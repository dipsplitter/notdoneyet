local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))

local startTime = os.clock()

local EnumService = Framework.GetShared("EnumService")
local Client = Framework.GetClient("Client")

-- NETWORK
local Network = Framework.Network()

local EntitySimulation = Framework.GetClient("ClientEntitySimulation")

local UiFramework = Framework.GetShared("UiFramework")
UiFramework.Initialize()

-- INPUT
local InputService = Framework.GetClient("InputService")

-- TODO: Remove this
Client.SetClass("Survivalist")

-- INITIALIZE SERVICES
local ItemsService = Framework.GetClient("ClientItemsService")

-- LOAD ASSETS
local AssetService = Framework.GetShared("AssetService")
AssetService.PreloadAll()

-- SOUND REPLICATION
local ReplicatedInstanceRemover = Framework.GetClient("ReplicatedInstanceRemover")
local AnimationEventService = Framework.GetClient("AnimationEventService")

local VisualsService = Framework.GetClient("ClientVisualsService")

local CharacterRegistry = Framework.GetShared("CharacterRegistry")

-- RANDOM
local RandomSeed = Framework.GetClient("ClientRandomSeed")
print(`[Client]: All main services loaded in {os.clock() - startTime} seconds.`)