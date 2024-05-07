local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)

local NETWORK = Framework.Network()
local SeedEvent = NETWORK.Event("Seed")

--[[
	Synchronize random seed for this client and the server
]]
local ClientRandomSeed = {
	Generator = Random.new(),
	
	ServerGenerator = nil,
}

-- Every set time interval, the server sends an RNG seed to the client
SeedEvent:Connect(function(data)
	ClientRandomSeed.Generator = Random.new(data.Seed)
end)

return ClientRandomSeed