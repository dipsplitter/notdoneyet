local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local TableUtilities = Framework.GetShared("TableUtilities")
local CreateEventMessages = Framework.GetShared("DT_CreateEventMessages")

local Network = Framework.Network()
local DataTableCreateEvent = Network.Event("DataTableCreate")

local Players = game:GetService("Players")

local playerDataTables = {}
local globalId = 0
local dataTables = {}
local stringNameToDataTable = {}

local function GetId(player)
	local entry = playerDataTables[player]
	
	if not entry then
		playerDataTables[player] = {
			Current = 0,
			FreeIds = {},
			DataTables = {},
		}
		entry = playerDataTables[player]
	end
	
	local id = entry.Current
	local freeIds = entry.FreeIds
	
	if #freeIds > 0 then
		id = freeIds[1]
		table.remove(freeIds, 1)
	else
		entry.Current += 1
	end

	return id
end

local function GetDataTableIdForPlayer(player, dataTable)
	local entry = playerDataTables[player].DataTables

	for dtId, dt in entry do
		if dt == dataTable then
			return dtId
		end
	end
end

local function AssociateDataTable(player, dataTable, hasPlayerReceivedInitialData)
	-- Add ID
	local id = GetId(player)
	playerDataTables[player].DataTables[id] = dataTable
	
	-- Add send table entry
	dataTable:RegisterPlayer(player, id, hasPlayerReceivedInitialData)
	
	CreateEventMessages.ServerAssociate(id, dataTable, player)
end

local function RemoveId(player, id)
	local entry = playerDataTables[player]
	table.insert(entry.FreeIds, id)
end

local function DissociateDataTable(player, dataTable)
	-- Clear ID
	local dataTableId = GetDataTableIdForPlayer(player, dataTable)
	RemoveId(player, dataTableId)
	
	-- Clear send table entry
	dataTable:RemovePlayer(player)
	
	playerDataTables[player].DataTables[dataTableId] = nil
	
	CreateEventMessages.ServerDissociate(dataTableId, player)
end

local DT_ServerIds = {
	DataTables = dataTables
}

function DT_ServerIds.Register(dataTable, havePlayersReceivedInitialData)
	local global = globalId
	globalId += 1
	
	if dataTable.PlayerContainer then
		local players = dataTable.PlayerContainer:Players()
		
		for i, player in players do
			AssociateDataTable(player, dataTable, havePlayersReceivedInitialData)
		end
	end
	
	dataTables[global] = dataTable
	
	return global
end

function DT_ServerIds.ChangeOwnership(dataTable, oldPlayerContainer, havePlayersReceivedInitialData)
	local oldPlayers = {}
	if oldPlayerContainer then
		oldPlayers = oldPlayerContainer:Players()
	end
	
	local newPlayers = {}
	local newPlayerContainer = dataTable.PlayerContainer
	if newPlayerContainer then
		newPlayers = newPlayerContainer:Players()
	end
	
	-- Don't do anything if players continue to be subscribed
	local samePlayers = TableUtilities.Intersection(oldPlayers, newPlayers)
	
	-- Destroy for old players
	for i, player in oldPlayers do
		if samePlayers[player] then
			continue
		end
		
		DissociateDataTable(player, dataTable)
	end 
	
	-- Create for new players
	for i, player in newPlayers do
		if samePlayers[player] then
			continue
		end
		
		AssociateDataTable(player, dataTable, havePlayersReceivedInitialData)
	end
end

function DT_ServerIds.Reference(id)
	if type(id) == "table" then

		for i, dt in dataTables do
			if dt == id then
				return dt
			end
		end

	end

	return dataTables[id]
end

function DT_ServerIds.Remove(dataTable)
	local globalId = dataTable
	
	if type(globalId) == "table" then
		globalId = dataTable.Id
	end
	
	if not globalId then
		return
	end

	if not dataTables[globalId] then
		return
	end
	
	local dataTableObject = dataTables[globalId]
	dataTables[globalId] = nil 
	
	if dataTableObject.PlayerContainer then
		for i, player in dataTableObject.PlayerContainer:Players() do
			DissociateDataTable(player, dataTableObject)
		end
	end
	
end

function DT_ServerIds.MarkReceiveTableCreated(dataTableId, player)
	local dataTables = playerDataTables[player].DataTables
	dataTables[dataTableId].PlayerReplicationData[player].ReceiveTableCreated = true
end

Players.PlayerAdded:Connect(function(player)
	if not playerDataTables[player] then
		playerDataTables[player] = {
			Current = 0,
			FreeIds = {},
			DataTables = {},
		}
	end

	for i, dataTable in dataTables do
		if dataTable.PlayerContainer:IsInContainer(player) then
			AssociateDataTable(player, dataTable)
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local playerEntry = playerDataTables[player]
	
	-- JUST SHUT UP
	if not playerEntry then
		return
	end

	local dataTables = playerEntry.DataTables
	for i, dataTable in dataTables do
		if dataTable.PlayerContainer:IsInContainer(player) then
			DissociateDataTable(player, dataTable)
		end
	end
	
	playerDataTables[player] = nil
end)

return DT_ServerIds
