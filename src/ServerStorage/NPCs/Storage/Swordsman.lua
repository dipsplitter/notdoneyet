local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local Config = Framework.GetShared("Swordsman")
local TableUtilities = Framework.GetShared("TableUtilities")
local RandomUtilities = Framework.GetShared("RandomUtilities")
local InstanceFilter = Framework.GetShared("InstanceFilter")

local NPC = Framework.GetServer("NPC")
local ItemsService = Framework.GetServer("ItemsService")
local Pathfinder = Framework.GetServer("Pathfinder")

local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local function RandomWeapon()
	local weapons = {
		--"Ignis",
		"ClassicSword",
		"Fists", 
		"PumpShotgun", 
	}
	return weapons[math.random(1, #weapons)]
end

local Swordsman = {}
Swordsman.__index = Swordsman
Swordsman.ClassName = "Swordsman"
setmetatable(Swordsman, NPC)

function Swordsman.new(params)
	params.NPCId = "Swordsman"
	local self = NPC.new(params)
	setmetatable(self, Swordsman)
	
	self.ItemInventory:SetHotbarSlots(Config.Inventory.Hotbars.Main.Slots)
	self.Attributes:SetNewBaseAttributes(Config.CharacterStats)
	self.CurrentActions = {
		SearchingForTarget = false,
	}
	
	self.TrackedTarget = nil
	
	self.Weapon = RandomWeapon()

	return self
end

function Swordsman:Spawn(...)
	self:BaseSpawn(...)
	self:Protect()
	self:SetupCoreAnimations()
	self:AddBaseIK()
	
	self.Weapon = ItemsService.Create({
		Character = self:GetModel(),
		Id = self.Weapon,
		IgnoreRestrictions = true,
	})
	
	self.Pathfinder = Pathfinder.new({
		Agent = self:GetModel(),
	})
	--self.Pathfinder.DebugMode = true
	
	if self.Weapon.Id == "PumpShotgun" or self.Weapon.Id == "FireballLauncher" then
		self.InputHandler:Press(Enum.KeyCode.One)
	else
		self.InputHandler:Press(Enum.KeyCode.Two)
	end

	
	self:AddConnections({
		WaypointReached = self.Pathfinder.Signals.WaypointReached:Connect(function(lastPoint, currentPoint, nextPoint)
			if not self:ShouldRecomputePath() then
				return
			end
			
			if not self.TrackedTarget then
				return
			end
			self.Pathfinder:Run(self:SelectTargetPosition())
		end),
		
		Blocked = self.Pathfinder.Signals.Blocked:Connect(function()
			if not self.TrackedTarget then
				return
			end
			self.Pathfinder:Run(self:SelectTargetPosition())
		end),
		
		Failed = self.Pathfinder.Signals.Failed:Connect(function()
			return
		end),
		
		Stuck = self.Pathfinder.Signals.Stuck:Connect(function()
			if not self.TrackedTarget then
				return
			end
			self.Pathfinder:Run(self:SelectTargetPosition())
		end),
	})
	
	self:AddConnections({
		MainThink = RunService.Heartbeat:Connect(function(dt)
			if os.clock() - self.LastThinkTime < self:GetStat("ThinkTime") then
				return
			end
			
			self.LastThinkTime = os.clock()
			
			self:Main()
		end),
	})
end

function Swordsman:IsTargetValid(target)
	local humanoid = target:FindFirstChild("Humanoid")
	if not humanoid then
		return false
	end
	
	return humanoid.Health > 0 and humanoid:GetState() ~= Enum.HumanoidStateType.Dead
end

function Swordsman:Attack()
	self.InputHandler:Press(Enum.UserInputType.MouseButton1)
end

function Swordsman:SelectTargetPosition()
	local velocity = self.TrackedTarget.PrimaryPart.AssemblyLinearVelocity
	
	return RandomUtilities.SelectRandomPointFromCircle(self.TrackedTarget.PrimaryPart.Position + (velocity * self:GetStat("ThinkTime")), 3)
end

function Swordsman:ShouldRecomputePath()
	local currentIndex = self.Pathfinder.WaypointMovingToIndex
	if currentIndex % 10 ~= 0 then
		return false
	end
	return true
end

function Swordsman:Main()
	self.Vision:Update()
	
	if not self.TrackedTarget then
		
		local filter = InstanceFilter.new("Include")
		filter:Add("Player")
		
		local currentTarget = self.Vision:GetClosestKnown(filter)
		
		if not currentTarget then
			return
		end
		-- Set the target to the one we're tracking
		self.TrackedTarget = currentTarget
	end

	local targetCharacter = self.TrackedTarget
	
	-- Is the target alive?
	if not self:IsTargetValid(targetCharacter) then
		self:ResetLookAt()
		self.TrackedTarget = nil
		return
	end
	
	if self.Vision:IsVisible(targetCharacter) then
		self:LookAt(targetCharacter)
		
		-- Can we see them completely?
		if self.Vision:IsInUnobstructedView(targetCharacter) then
			-- Stop pathfinding and directly move to the target
			if self.Pathfinder.Active then
				self.Pathfinder:ResetPath()
			end 
			
			self:MoveTo(self:SelectTargetPosition())
			
		else
			
			if not self.Pathfinder.Active then
				self.Pathfinder:Run(self:SelectTargetPosition())
			end
			
		end
		
		if self:GetDistanceToTarget(targetCharacter) <= 30 then
			self:Attack()
		end
		
	else
		
		
		self:ResetLookAt()
		
		if not self.Pathfinder.Active then
			self.Pathfinder:Run(self:SelectTargetPosition())
		end
		
	end
end

return Swordsman
