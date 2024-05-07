local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")

local ClientNPC = {}
ClientNPC.__index = ClientNPC
ClientNPC.ClassName = "ClientNPC"
setmetatable(ClientNPC, BaseClass)

function ClientNPC.new()
	
end

return ClientNPC
