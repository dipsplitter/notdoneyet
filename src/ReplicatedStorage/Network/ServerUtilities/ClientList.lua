local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local Signal = Framework.GetShared("Signal")

local Players = game:GetService("Players")

local clients = {}

local ClientList = {
	ClientAdded = Signal.new(),
	ClientRemoving = Signal.new(),
}

for i, player in Players:GetPlayers() do
	clients[player] = true
	ClientList.ClientAdded:Fire(player)
end

Players.PlayerAdded:Connect(function(player)
	clients[player] = true
	ClientList.ClientAdded:Fire(player)
end)

Players.PlayerRemoving:Connect(function(player)
	clients[player] = nil
	ClientList.ClientRemoving:Fire(player)
end)

return ClientList
