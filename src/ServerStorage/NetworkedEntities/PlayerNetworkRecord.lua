local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local NETWORK = Framework.Network()
local Globals = Framework.GetShared("Globals")
local EntityService = Framework.GetShared("EntityService")
local DataTableService = Framework.GetShared("DataTableService")
local SettingsStructures = Framework.GetShared("DTS_Settings")
local RetrieveSnapshot = Framework.GetShared("DT_RetrieveSnapshot")

local MAXIMUM_COMMAND_DEFECIT = 3

local PlayerNetworkRecord = {}
PlayerNetworkRecord.__index = PlayerNetworkRecord

function PlayerNetworkRecord.new(player)
	local self = {
		Player = player,
		IsNetworked = true,
		
		LastAcknowledgedUpdateTick = 0,
		LatestAppliedCommandId = 0,
		NextUpdateTime = -1,
		
		CommandBuffer = {}, -- commands received, and not yet processed
		CommandDefecit = 0, -- keep track of when we lack commands, and run extra if we get more of them later
		CommandQueue = {}, -- run all commands in the queue on next tick 
		
		ClientSettings = DataTableService.Reference({
			Name = `NS{player.UserId}`,
			PlayerContainer = NETWORK.Single(player),
			Structure = `Settings.Network`,
			Data = SettingsStructures.DefaultValues.Network, -- TODO: Pull from a data store!
		}),
	}
	
	setmetatable(self, PlayerNetworkRecord)
	
	return self
end

function PlayerNetworkRecord:Update(ticks)
	if time() < self.NextUpdateTime then
		return false
	end
	
	local updateFrequency = 1 / self.ClientSettings:Get("MinimumUpdateRate")
	local ticksAhead = math.floor((time() - self.NextUpdateTime) / updateFrequency) + 1
	self.NextUpdateTime += updateFrequency * ticksAhead
	
	return true
end

function PlayerNetworkRecord:FullSnapshot(sendQueue)
	for handle, entity in EntityService.List do
		local dataTable = entity.DataTable
		if not dataTable:IsPlayerValid(self.Player) then
			continue
		end

		local fullSnapshot = RetrieveSnapshot.FullSnapshot(dataTable, self.Player)

		sendQueue:Add(fullSnapshot, self.Player)
	end

	self.LastAcknowledgedUpdateTick = 0
end

function PlayerNetworkRecord:DeltaSnapshot(sendQueue, comparisonSnapshot)
	local removedEntities = {}
	for handle, entity in comparisonSnapshot.States do
		if not EntityService.List[handle] then
			table.insert(removedEntities, handle)
		end
	end

	for handle, entity in EntityService.List do
		local dataTable = entity.DataTable
		if not dataTable:IsPlayerValid(self.Player) then
			continue
		end

		local snapshot = RetrieveSnapshot.Snapshot(dataTable, self.Player, comparisonSnapshot.States[handle])
		if not snapshot then -- This means the entity has NOT changed... but it has not been destroyed!
			continue
		end
		
		sendQueue:Add(snapshot, self.Player)
	end
	
	return removedEntities
end

-- Clears outdated commands and spam
function PlayerNetworkRecord:ClearInvalidCommands()
	local commandBuffer = self.CommandBuffer
	
	while true do
		local command = commandBuffer[1]

		-- Discard excess commands because they'll be useless when we need to do any hitbox rewinding
		if command and command.Tick < EntityService.HistoryBuffer:GetFirst().Tick then
			table.remove(commandBuffer, 1) -- Discard this command from the buffer without applying it
		else
			break
		end
	end

	if #commandBuffer > ((1 / self.ClientSettings:Get("CommandRate")) / Globals.TickRate) + 2 then
		-- ignore commands if too many are sent at once
		table.clear(commandBuffer)
	end
end

function PlayerNetworkRecord:ProcessCommands(currentTick)
	local unprocessedCommand = self.CommandBuffer[1]
	
	if not unprocessedCommand then
		
		if self.CommandDefecit < MAXIMUM_COMMAND_DEFECIT then
			self.CommandDefecit += 1
		end
		
		return
	end
	
	while unprocessedCommand do
		table.insert(self.CommandQueue, unprocessedCommand)
		table.remove(self.CommandBuffer, 1)
		
		local acknowledgedTick = unprocessedCommand.LatestUpdateTick

		-- Discard, as it arrived out of order
		if acknowledgedTick < self.LastAcknowledgedUpdateTick then
			continue
		end
		
		self.LatestAppliedCommandId = unprocessedCommand.Id
		
		if acknowledgedTick > 0 then
			self.LastAcknowledgedUpdateTick = unprocessedCommand.LatestUpdateTick
		end
		
		if self.CommandDefecit > 0 then
			self.CommandDefecit -= 1
		end
		
		-- No defecit, so done processing commands
		if self.CommandDefecit == 0 then
			break
		end
		
		unprocessedCommand = self.CommandBuffer[1]
		if not unprocessedCommand and self.CommandDefecit > MAXIMUM_COMMAND_DEFECIT then
			-- Insert blank command so we don't freeze
			unprocessedCommand = {
				Tick = currentTick,
				Id = 0,
			}
		end
		
	end
end

return PlayerNetworkRecord
