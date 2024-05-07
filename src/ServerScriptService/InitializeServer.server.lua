local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)

local Network = Framework.Network()

local EnumService = Framework.GetShared("EnumService")

local EntitySimulation = Framework.GetServer("ServerEntitySimulation")

local ItemsService = Framework.GetServer("ItemsService")

local PlayerRegistry = Framework.GetServer("PlayerRegistry")

local VisualsReplicator = Framework.GetServer("VisualsReplicator")

local CharacterRegistry = Framework.GetServer("CharacterRegistry")

local DamageService = Framework.GetServer("DamageService")
local StatusEffectService = Framework.GetServer("StatusEffectService")

local RandomSeedNetwork = Framework.GetServer("RandomSeedNetwork")

local AssetService = Framework.GetShared("AssetService")

local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		task.wait(0.1)
		
		local class = CharacterRegistry.GetClass(char)
		if class == "Soldier" then
			ItemsService.Create({
				Id = "RocketLauncher",
				Character = char,
			})
			ItemsService.Create({
				Id = "PumpShotgun",
				Character = char,
			})
		elseif class == "Fatman" then
			ItemsService.Create({
				Id = "PumpShotgun",
				Character = char,
			})

			ItemsService.Create({
				Id = "Fists",
				Character = char,
			})
		elseif class == "Survivalist" then
			ItemsService.Create({
				Id = "RitualAxe",
				Character = char,
			})

			ItemsService.Create({
				Id = "FlareGun",
				Character = char,
			})

			ItemsService.Create({
				Id = "REX",
				Character = char,
			})

			ItemsService.Create({
				Id = "FireballLauncher",
				Character = char,
			})
		elseif class == "Warrior" then
			ItemsService.Create({
				Id = "Ignis",
				Character = char,
			})
		elseif class == "Medic" then
			ItemsService.Create({
				Id = "ClassicSword",
				Character = char,
			})
		end
		
		
	end)
end)

local SPAWN_THESE_GUYS = true
local Character = Framework.GetServer("Character")
local NPC = Framework.GetServer("NPC")
local Swordsman = Framework.GetServer("Swordsman")

local region = workspace.Map.SpawnRegions.SpawnRegion

local d = Character.new({
	Model = workspace.Rig,
})
d.Attributes:SetNewBaseAttributes({
	Health = 500000,
	Armor = 500000,
})
d:Spawn(nil, {Region = "DummySpawn"})

local healthOnly = Character.new({
	Model = workspace.Rig,
})
healthOnly.Attributes:SetNewBaseAttributes({
	Health = 1000000,
	Armor = 0,
})
healthOnly:Spawn(nil, {Region = "DummySpawn"})

if SPAWN_THESE_GUYS then
	local guys = {}
	
	local theGang = workspace.Things:GetChildren()
	
	local function CreateDude(dude)
		local npc = Swordsman.new({
			SpawnRegions = {
				Regions = {
					[region] = {
						["Random"] = true
					}
				},
			},
			Model = dude,
		})
		npc:Spawn(nil, {Region = "NPCSpawn"})
		
		guys[dude] = npc
		
		npc:ConnectTo("Died", function()
			guys[dude] = nil
			
			task.delay(8, function()
				npc:Destroy()
			end)
	
			CreateDude(dude)
		end)
		
		return npc
	end
	
	for i, dude in theGang do
		task.spawn(CreateDude, dude)
	end
end
