local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)

local Players = game:GetService("Players")

local NETWORK = Framework.Network()
local SeedEvent = NETWORK.Event("Seed")

local players = {}
local serverSeed = math.randomseed(tick())

local RandomSeedNetwork = {}

local function GenerateSeedForPlayer(player)
	local generated = workspace:GetServerTimeNow()
	
	SeedEvent:Fire({
		Seed = generated
	}, player)
	
	return Random.new(generated)
end

Players.PlayerAdded:Connect(function(player)
	players[player] = GenerateSeedForPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
	players[player] = nil
end)

return RandomSeedNetwork
