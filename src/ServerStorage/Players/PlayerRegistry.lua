local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local Player = Framework.GetServer("Player")

local NETWORK = Framework.Network()
local ChangeClassEvent = NETWORK.Event("ChangeClass")

local Players = game:GetService("Players")

local playerList = {}

local PlayerRegistry = {}

function PlayerRegistry.GetPlayer(playerObject)
	return playerList[playerObject.UserId]
end

Players.PlayerAdded:Connect(function(player)
	local userId = player.UserId
	playerList[userId] = Player.new(player)
end)

Players.PlayerRemoving:Connect(function(player)
	local userId = player.UserId
	if playerList[userId] then
		playerList[userId]:Destroy()
		playerList[userId] = nil
	end
end)

-- Bridge connections
ChangeClassEvent:Connect(function(className, player)
	-- TODO: Check if we can switch to this class
	local playerObject = playerList[player.UserId]
	playerObject:SetNextClass(className)
end)

return PlayerRegistry
