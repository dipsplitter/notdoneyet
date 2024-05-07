local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")
local Raycaster = Framework.GetShared("Raycaster")
local DistanceUtilities = Framework.GetShared("DistanceUtilities")
local RaycastUtilities = Framework.GetShared("RaycastUtilities")

local KnownEntity = Framework.GetServer("NPCKnownEntity")

local VisibleEntities = {}
VisibleEntities.__index = VisibleEntities

function VisibleEntities.new(vision)
	local self = setmetatable({
		Vision = vision,
		Entries = {},
	}, VisibleEntities)
	
	return self
end

function VisibleEntities:Add(character)
	if character 
		and self.Vision:IsAbleToSee(character) 
		and not self.Vision:IsIgnored(character) 
		and not self:Contains(character) then
		
		self.Entries[character] = true
	end
end

function VisibleEntities:Contains(character)
	if self.Entries[character] then
		return true
	end
	
	return false
end

local NPCVision = {}
NPCVision.__index = NPCVision
NPCVision.ClassName = "NPCVision"
setmetatable(NPCVision, BaseClass)

function NPCVision.new(npc)
	local self = BaseClass.new()
	setmetatable(self, NPCVision)
	
	self:InjectObject("NPC", npc)
	self.Raycaster = Raycaster.new({
		IgnoreList = {self.NPC:GetModel()},
		ShouldConvertRaycastResult = false,
	})
	
	self.LastUpdateTime = 0
	
	self.Candidates = {} -- Children of workspace.Characters, everything that should be tested for visibility
	self.KnownEntities = {} -- Entities that we are aware of and can act on
	
	self.CheckFOV = true
	
	self:AddSignals("EnteredVision", "LeftVision")
	
	return self
end

function NPCVision:UpdateCandidates()
	table.clear(self.Candidates)
	local characters = workspace.Characters
	
	for i, character in pairs(characters:GetChildren()) do
		if character == self.NPC:GetModel() then
			continue
		end
		
		self.Candidates[character] = true
	end
end

-- Known entities
function NPCVision:AddKnownEntity(entity)
	if self.KnownEntities[entity] then
		return
	end
	
	self.KnownEntities[entity] = KnownEntity.new(entity)
	return self.KnownEntities[entity]
end

function NPCVision:ForgetKnownEntity(entity)
	local entry = self.KnownEntities[entity]
	if not entry then
		return
	end
	
	entry:Destroy()
	self.KnownEntities[entity] = nil
end

function NPCVision:ForgetAllKnownEntities()
	for entity, knownEntityEntry in pairs(self.KnownEntities) do
		self:ForgetKnownEntity(entity)
	end
end

function NPCVision:GetKnownEntities()
	local entitiesTable = {}
	for entity, knownEntityEntry in pairs(self.KnownEntities) do
		table.insert(entitiesTable, entity)
	end
	
	return entitiesTable
end

function NPCVision:IsIgnored(character)
	local visionIgnoreList = self.NPC.VisionIgnoreList
	if not visionIgnoreList then
		return false
	end
	
	if visionIgnoreList[character] then
		return true
	end
	
	return false
end

function NPCVision:IsAwareOf(knownEntity)
	return knownEntity:GetTimeSinceBecameKnown() >= self.NPC:GetStat("MinVisualReactionTime")
end

function NPCVision:UpdateKnownEntities()
	self:UpdateCandidates()
	
	local visibleEntities = VisibleEntities.new(self)
	for character in pairs(self.Candidates) do
		visibleEntities:Add(character)
	end
	
	local reactionTime = self.NPC:GetStat("MinVisualReactionTime") 
	
	for character, entry in pairs(self.KnownEntities) do
		-- Clear dead or nonexistent entities
		if entry:IsObsolete() then
			self:ForgetKnownEntity(character)
		end
		
		-- Character is visible and already known
		if visibleEntities:Contains(entry.Character) then
			entry:UpdatePosition()
			entry:UpdateVisibility(true)
			
			-- Has our reaction time passed?
			if os.clock() - entry.LastBecameVisible >= reactionTime
				and self.LastUpdateTime - entry.LastBecameVisible < reactionTime then
				
				self:FireSignal("EnteredVision", entry.Character)
			end
		else
			
			if entry.IsVisible then
				-- We can't see them but we still know they exist
				entry:UpdateVisibility(false)
				self:FireSignal("LeftVision", entry.Character)
			end
			
			if not entry.LastKnownPositionSeen then
				-- Can we see their last known position?
				if self:IsAbleToSee(entry.LastKnownPosition) then
					entry:MarkLastKnownPositionAsSeen()
				end
			end
		end
	end
	
	-- Now add any new characters to the known entities list
	for character in pairs(visibleEntities.Entries) do
		
		if self.KnownEntities[character] then
			continue
		end
		
		local known = self:AddKnownEntity(character)
		known:UpdatePosition()
		known:UpdateVisibility(true)
		
	end
	
	visibleEntities.Entries = nil
end

function NPCVision:Update()
	self:UpdateKnownEntities()
	self.LastUpdateTime = os.clock()
end

function NPCVision:IsInFOV(target, fov)
	-- FOV in degrees (90 -> 0 dot product, 180 -> -1 dot product)
	fov = fov or self.NPC:GetStat("FOV")
	
	local head = self.NPC:GetModelPart("Head")

	local npcToTarget = DistanceUtilities.GetUnitDirectionTo(target, head)
	local headLookVector = head.CFrame.LookVector

	local dotProduct = npcToTarget:Dot(headLookVector)

	return math.cos(math.rad(fov)) <= dotProduct
end

function NPCVision:IsInLineOfSight(target, range, raycastParams)
	range = range or self.NPC:GetStat("MaxVisionRange")
	raycastParams = raycastParams or self.NPC:GetStat("VisionRaycastParams")
	
	local headPosition = self.NPC:GetModelPart("Head").Position
	
	local resultsTable = self.Raycaster:Cast(headPosition, 
		(DistanceUtilities.GetPosition(target) - headPosition).Unit, 
		range, 
		raycastParams)
	
	-- No result
	if not resultsTable then
		return true
	end
	
	local raycastResult = resultsTable[1]
	local hitInstance = raycastResult.Instance
	
	-- Is there nothing in the way? If we're checking a position, is the raycast result position the same?
	if not hitInstance or (typeof(target) == "Vector3" and DistanceUtilities.ArePositionsEqual(raycastResult.Position, target)) then
		return true
	end
	
	return RaycastUtilities.InstanceIsDescendant(raycastResult, target)
end

-- Uses a 3D query instead of a single ray
function NPCVision:IsInUnobstructedView(target, range, querySize, raycastParams)
	range = range or self.NPC:GetStat("MaxVisionRange")
	querySize = querySize or self.NPC:GetBoundingBoxSize()
	raycastParams = raycastParams or self.NPC:GetStat("VisionRaycastParams")
	
	local pivot = self.NPC:GetModel():GetPivot()

	local resultsTable = self.Raycaster:Blockcast(
		pivot, 
		querySize, 
		(DistanceUtilities.GetPosition(target) - pivot.Position).Unit * range, 
		raycastParams)

	if not resultsTable then
		return true
	end

	local raycastResult = resultsTable[1]
	
	local hitInstance = raycastResult.Instance

	if not hitInstance then
		return true
	end
	
	return RaycastUtilities.InstanceIsDescendant(raycastResult, target)
end

function NPCVision:IsAbleToSee(target, checkFOV)
	if not target then
		return false
	end
	
	local distance = DistanceUtilities.GetDistance(target, self.NPC:GetModel())
	if distance > self.NPC:GetStat("MaxVisionRange") or distance < self.NPC:GetStat("MinVisionRange") then
		return false
	end
	
	if checkFOV == nil then
		checkFOV = self.CheckFOV
	end
	
	if checkFOV and not self:IsInFOV(target) then
		return false
	end
	
	if not self:IsInLineOfSight(target) then
		return false
	end
	
	return true
end

function NPCVision:IsLookingAt(position, degreesTolerance)
	degreesTolerance = degreesTolerance or 3
	return self:IsInFOV(position, degreesTolerance)
end

function NPCVision:IsVisible(character)
	local knownEntityEntry = self.KnownEntities[character]
	if not knownEntityEntry then
		return false
	end
	
	return knownEntityEntry.IsVisible
end

-- Uses an InstanceFilter
function NPCVision:GetClosestKnown(filter, evaluator)
	local function DistanceCheckEvaluator(target, pos)
		if filter then
			return not filter:ShouldIgnore(target)
		end
		
		if evaluator then
			return evaluator(target, pos)
		end
		
		return true
	end
	
	return DistanceUtilities.GetClosest({
		Targets = self:GetKnownEntities(),
		MaxDistance = self.NPC:GetStat("MaxVisionRange"),
		MinDistance = self.NPC:GetStat("MinVisionRange"),
		Center = self.NPC:GetPosition(),
		Evaluator = DistanceCheckEvaluator,
	})
end

return NPCVision