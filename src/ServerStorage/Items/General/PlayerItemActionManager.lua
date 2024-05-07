local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local ItemActionManager = Framework.GetShared("ItemActionManager")

local NETWORK = Framework.Network()
local ItemActionEvent = NETWORK.Event("ItemAction")

local PlayerItemActionManager = {}
PlayerItemActionManager.__index = PlayerItemActionManager
PlayerItemActionManager.ClassName = "PlayerItemActionManager"
setmetatable(PlayerItemActionManager, ItemActionManager)

function PlayerItemActionManager.new(params)
	local self = ItemActionManager.new(params)
	setmetatable(self, PlayerItemActionManager)
	
	self:DisableAllInputListeners() -- We don't need to listen to any simulated input
	
	self.Player = self.Item.Player
	self.IsNetworked = true
	-- The item's id
	self.EntityHandle = self.Item.EntityHandle
	
	return self
end

-- TODO: Very important in the future!!!! Call a validation function here
function PlayerItemActionManager:StartActionEventFromClientRequest(args)
	local action = self:GetAction(args.ActionName)
	if not action then
		return
	end
	
	args.ClientInitiated = true
	
	action:StartEvent(args.EventName, args)
end

function PlayerItemActionManager:FireClient(argsTable)
	local netArgs = {
		ActionManager = self,
		EventName = argsTable.EventName,
		ActionName = argsTable.ActionName,
		Args = argsTable.Args
	}

	ItemActionEvent:Fire(netArgs, self.Player)
end

function PlayerItemActionManager:StartActionEventWithReplication(args)
	if args.ClientInitiated then
		return
	end
	
	local action = self:GetAction(args.ActionName)
	if not action then
		return
	end
	
	action:StartEvent(args.EventName, args)
	
	self:FireClient(args)
end

return PlayerItemActionManager
