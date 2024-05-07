local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local RandomUtilities = Framework.GetShared("RandomUtilities")

local MapFolder = workspace.Map

local CharacterSpawner = {}

--[[
	Region spawn parameters:
	
	Region: string
		If it matches the name of a specific spawn region, that region is selected
		Otherwise, it is treated as a tag, and we pick a random tagged spawn region
				
	RandomPosition: boolean (defaults to true)
		Picks a random position within the chosen region to spawn
]]
function CharacterSpawner.SpawnAtRegion(character, regionParams)
	regionParams.RandomPosition = regionParams.RandomPosition or (regionParams.RandomPosition == nil)
	
	local currentSpawnRegions = MapFolder.SpawnRegions
	local activeModel = character.ActiveModel
	
	local region = regionParams.Region
	local cframe = nil
	
	local selectedSpawnRegion = if region then currentSpawnRegions:FindFirstChild(region) else nil
	if not selectedSpawnRegion then
		local taggedSpawnRegions = CollectionService:GetTagged(region)
		
		selectedSpawnRegion = RandomUtilities.SelectRandomFromArray(taggedSpawnRegions)
	end
	
	local boundingBox = activeModel:GetBoundingBox()

	if regionParams.RandomPosition then
		cframe = RandomUtilities.SelectRandomPartPositionFromBox(selectedSpawnRegion, boundingBox)
		
		-- Set the Y so that their feet will touch the ground (or the bottom face of the region)
		cframe = CFrame.new(cframe.X, selectedSpawnRegion.Position.Y - selectedSpawnRegion.Size.Y / 2 + boundingBox.Size.Y, cframe.Z) * cframe.Rotation
	end
	
	activeModel.Model:PivotTo(cframe)
end

function CharacterSpawner.SpawnAtPosition(character, positionParams)
	
end

function CharacterSpawner.Spawn(character, params)
	if not params then
		return
	end
	
	if params.Region then
		CharacterSpawner.SpawnAtRegion(character, params)
	else
		CharacterSpawner.SpawnAtPosition(character, params)
	end
end

return CharacterSpawner
