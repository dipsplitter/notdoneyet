local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")
local ProjectileSchema = Framework.GetShared("ProjectileSchema")
local TableUtilities = Framework.GetShared("TableUtilities")
local ModelUtilities = Framework.GetShared("ModelUtilities")
local PhysicsUtilities = Framework.GetShared("PhysicsUtilities")
local InstanceUtilities = Framework.GetShared("InstanceUtilities")
local ProjectileNetworker = Framework.GetShared("ProjectileNetworker")

local Client = Framework.GetClient("Client")

local IsClient = RunService:IsClient()
local IsServer = RunService:IsServer()

-- Sets constructor arguments
local function SetProjectileClassProperties(className, params)
	local propertiesScript = ProjectileSchema.GetPropertyScript(className)
	
	params.ModelTemplate = propertiesScript:FindFirstChildWhichIsA("Model")
	params.DefaultProperties = ProjectileSchema.GetBaseProperties(className)
end

local Projectile = {}
Projectile.__index = Projectile
Projectile.ClassName = "Projectile"
setmetatable(Projectile, BaseClass)

function Projectile.new(params)
	local self = BaseClass.new()
	setmetatable(self, Projectile)
	
	self:AddSignals("Touched", "Destroying", "Event", "OtherProjectileTouched")
	
	self.Id = params.Id
	
	SetProjectileClassProperties(self.Id, params)
	
	self.Stats = params.Stats or {}
	local defaultStats = params.DefaultProperties
	
	self.Stats = TableUtilities.DeepMerge(defaultStats, self.Stats)
	
	-- We can make a projectile out of an existing model
	if params.Model then
		self.Model = params.Model
	else
		local model = params.ModelTemplate
		self.Model = model:Clone()
	end
	
	self.EntityHandle = params.EntityHandle

	ProjectileNetworker.SetDataTable(self)
	
	self.Model:SetAttribute("ID", self.EntityHandle)
	
	local collisionGroup = self.Stats.CollisionGroup or "Projectile"
	self.BoundingBox = PhysicsUtilities.CreateBoundingBoxPart(self.Model)
	self.BoundingBox.CollisionGroup = collisionGroup

	ModelUtilities.SetCollisionGroup(self.Model, collisionGroup)
	
	--[[ 
		Spawner: the item
		Creator: the item's owner or the character that spawned the projectile, cannot change
	]]
	if IsServer then
		self.Spawner = params.Spawner
		self.Creator = params.Creator or if self.Spawner.Character then self.Spawner.Character else nil
	end
	
	self.CurrentOwner = self.Creator

	self.Lifetime = 0
	
	self.CanTouch = true
	self.Destroying = false
	
	self.OverlapParams = OverlapParams.new()
	self.OverlapParams.CollisionGroup = collisionGroup
	self.OverlapParams.FilterDescendantsInstances = {self.CurrentOwner}
	
	self.RaycastParams = RaycastParams.new()
	self.RaycastParams.CollisionGroup = collisionGroup
	self.RaycastParams.FilterDescendantsInstances = {self.CurrentOwner}

	return self
end

function Projectile:GetStat(name)
	return self.Stats[name]
end

function Projectile:SetNetworkOwner()
	if not Framework.IsServer then
		return
	end
	
	--[[
	local client = self:GetCurrentOwnerPlayer()
	
	if client then
		ModelUtilities.SetClientOwned(self.Model, client)
	else
		ModelUtilities.SetServerOwned(self.Model)
	end
	]]
	
	ModelUtilities.SetServerOwned(self.Model)
	--ModelUtilities.SetShared(self.Model)
end

function Projectile:ChangeCurrentOwner(character)
	self.CurrentOwner = character
end

function Projectile:GetCurrentOwnerPlayer()
	return Players:GetPlayerFromCharacter(self.CurrentOwner)
end

function Projectile:GetCurrentOwner()
	return self.CurrentOwner
end

function Projectile:Spawn()
	-- TODO
	if true then
		self.Model.Parent = workspace.Projectiles
	else
		self.Model.Parent = workspace.Camera.Projectiles
	end
	
	self:SetNetworkOwner()
end

function Projectile:CheckPartBounds()
	-- TODO: Make this multithreaded
	self:AddConnections({
		PostSimPartBounds = RunService.PostSimulation:Connect(function(dt)
			if not self.CanTouch or not self.DataTable then
				return
			end

			if not next(self.DataTable) then
				return
			end
			
			local results = workspace:GetPartBoundsInBox(self.DataTable:Get("CFrame"), self.BoundingBox.Size, self.OverlapParams)
			results = self:EvaluateTouchQueryResults(results)
			
			if #results > 0 then
				self:FireSignal("Touched", results)

				if not self.BoundingBox.CanCollide and not self.Destroying then
					ModelUtilities.SetCollidable(self.Model, true)
				end
			end
		end)
	})
end

function Projectile:Raycast()
	--TODO: Make this multithreaded
	self:AddConnections({
		PostSimRaycast = RunService.PostSimulation:Connect(function(dt)
			if not self.CanTouch or not self.DataTable then
				return
			end
			
			if not next(self.DataTable) then
				return
			end
			
			local currentPosition = self.DataTable:Get("CFrame").Position
			local direction = self.DataTable:Get("Velocity") * dt
			local result = workspace:Raycast(currentPosition, direction, self.RaycastParams)
			result = self:EvaluateRaycastQueryResult(result)
			
			if #result > 0 then
				self:FireSignal("Touched", result)
				
				if not self.BoundingBox.CanCollide and not self.Destroying then
					ModelUtilities.SetCollidable(self.Model, true)
				end
			end
		end)
	})
end

function Projectile:Anchor(value)
	ModelUtilities.Anchor(self.Model, value)
end

function Projectile:IsAnchored()
	return self.Model.PrimaryPart.Anchored
end

function Projectile:Stage()
	self:AddBaseConnections()
	ModelUtilities.SetCollidable(self.Model, false)
	self:Spawn()
	self:AddAntiGravityForce()
	
	task.delay(0, function()
		self:CheckPartBounds()
		self:Raycast()
	end)
	
	self.EnableCollisionTask = task.delay(0.15, function()
		ModelUtilities.SetCollidable(self.Model, true)
		
		self.EnableCollisionTask = nil
	end)
end

function Projectile:PositionMainAttachment()
	local primaryPart = self.Model.PrimaryPart
	local main = primaryPart:FindFirstChild("Main")
	
	main.Position = primaryPart.CenterOfMass
end

function Projectile:DisableAllVisuals()
	for i, descendant in pairs(self.Model:GetDescendants()) do
		-- TODO: Util for this
		pcall(function()
			descendant.Enabled = false
		end)
	end
end

function Projectile:ScheduleForDeletion(t)
	if self.Destroying then
		return
	end
	
	self.Destroying = true
	
	if self.EnableCollisionTask then
		task.cancel(self.EnableCollisionTask)
		self.EnableCollisionTask = nil
	end
	
	ModelUtilities.Lock(self.Model, true)
	ModelUtilities.SetTransparency(self.Model, 1)
	self:CleanupAllConnections()
	self:DisableAllVisuals()
	
	ProjectileNetworker.Destroy(self)
	
	if self.DataTable then
		self.DataTable:Destroy()
	end
	
	task.delay(t or 15, self.Destroy, self)
end

function Projectile:PivotToLookAt(origin, direction)
	local offset = self:GetStat("SpawnOffset") or CFrame.new()
	
	origin *= offset
	
	self:PivotTo(CFrame.lookAt(origin.Position, origin.Position + direction * 500))
	
	self.DataTable:Set("CFrame", self.Model:GetPivot())
	self.DataTable:Set("Velocity", Vector3.zero)
end

function Projectile:ToggleCanTouch(state)
	self.CanTouch = state
end

function Projectile:PivotTo(position)
	ModelUtilities.PivotTo(self.Model, position)
end

function Projectile:AddBaseConnections()
	self:AddConnections({
		TrackProjectileProperties = RunService.PostSimulation:Connect(function(dt)
			if not self.Model then
				return
			end
			
			if not self.Model.PrimaryPart then
				return
			end
			
			self.DataTable:Set("CFrame", self.Model:GetPivot())
			self.DataTable:Set("Velocity", self.Model.PrimaryPart.AssemblyLinearVelocity)
			
			self.Lifetime += dt	
		end),
		
		BoundingBoxTouched = self.BoundingBox.Touched:Connect(function(touchedPart)
			if not self.CanTouch then
				return
			end
			
			local results = {touchedPart}
			results = self:EvaluateTouchQueryResults(results)
			
			if #results == 0 then
				return
			end
			
			self:FireSignal("Touched", results)
		end)
	})
end

function Projectile:EvaluateTouchQueryResults(queryResults)
	-- We can accept all the touch results
	if self:GetStat("CanTouchOwner") then
		return queryResults
	end
	
	return TableUtilities.Filter(queryResults, function(result)
		
		local model = InstanceUtilities.GetCharacterAncestor(result)
		if model == self.CurrentOwner or model == self.Model then
			return false
		end
		
		return true
	end)
end

function Projectile:EvaluateRaycastQueryResult(raycastResult)
	local partsTable = {}
	if not raycastResult then
		return partsTable
	end
	
	local instance = raycastResult.Instance
	
	if self:GetStat("CanTouchOwner") then
		table.insert(partsTable, instance)
		return partsTable
	end
	
	local model = InstanceUtilities.GetCharacterAncestor(instance)
	if model ~= self.CurrentOwner and model ~= self.Model then
		table.insert(partsTable, instance)
	end

	return partsTable
end

function Projectile:ApplyImpulse(params)
	if self:IsAnchored() then
		self:Anchor(false)
	end
	
	params = params or {}
	local xVel = (params.HorizontalVelocity or self:GetStat("HorizontalVelocity") or 0) * (params.HorizontalMultiplier or 1)
	local yVel = (params.VerticalVelocity or self:GetStat("VerticalVelocity") or 0) * (params.VerticalMultiplier or 1)
	local direction = params.Direction or self.Model.PrimaryPart.CFrame.LookVector
	
	local primaryPart = self.Model.PrimaryPart
	
	local velocity = xVel * direction + Vector3.new(0, yVel, 0)
	
	local shouldIgnoreMass = self:GetStat("ImpulseIgnoresMass")
	if shouldIgnoreMass == nil then
		shouldIgnoreMass = params.IgnoreMass
	end
	
	if shouldIgnoreMass then
		velocity *= primaryPart.AssemblyMass
	end
	
	primaryPart:ApplyImpulse(velocity)
end

function Projectile:AddAntiGravityForce(scale)
	local gravityScale = scale or self:GetStat("GravityScale")
	if not gravityScale then
		return
	end
	
	local primaryPart = self.Model.PrimaryPart

	local antiGravity = Instance.new("VectorForce")
	antiGravity.Name = "AntiGravity"
	antiGravity.ApplyAtCenterOfMass = true
	antiGravity.Attachment0 = primaryPart:FindFirstChild("Main")
	antiGravity.RelativeTo = Enum.ActuatorRelativeTo.World
	antiGravity.Force = Vector3.new(0, primaryPart.AssemblyMass * workspace.Gravity * gravityScale, 0)
	antiGravity.Parent = primaryPart
	
	return antiGravity
end

function Projectile:SetLinearVelocity(velocity)
	if self:IsAnchored() then
		self:Anchor(false)
	end
	
	local primaryPart = self.Model.PrimaryPart

	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Name = "LinearVelocity"
	linearVelocity.Attachment0 = primaryPart:FindFirstChild("Main")
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.VectorVelocity = primaryPart.CFrame.LookVector * self:GetStat("HorizontalVelocity")
	linearVelocity.Enabled = true
	linearVelocity.Parent = primaryPart

	return linearVelocity
end

function Projectile:SetMaxTorque(torque)
	local primaryPart = self.Model.PrimaryPart
	
	local angularVelocity = primaryPart:FindFirstChildOfClass("AngularVelocity")
	if not angularVelocity then
		angularVelocity = Instance.new("AngularVelocity")
		angularVelocity.Attachment0 = primaryPart:FindFirstChild("Main")
		angularVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
		angularVelocity.Enabled = true
		angularVelocity.Parent = primaryPart
	end
	
	angularVelocity.MaxTorque = torque
	
	return angularVelocity
end

function Projectile:SetAngularVelocity(velocity)
	local primaryPart = self.Model.PrimaryPart

	local angularVelocity = primaryPart:FindFirstChildOfClass("AngularVelocity")
	if not angularVelocity then
		angularVelocity = Instance.new("AngularVelocity")
		angularVelocity.Attachment0 = primaryPart:FindFirstChild("Main")
		angularVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
		angularVelocity.Enabled = true
		angularVelocity.Parent = primaryPart
	end

	angularVelocity.AngularVelocity = velocity

	return angularVelocity
end

function Projectile:ForgetModel()
	self:CleanupAllConnections()
	self.Model = nil
end

function Projectile:Destroy()
	if self.Model then
		self.Cleaner:Add(self.Model)
	end

	self.Spawner = nil
	
	BaseClass.Destroy(self)
end

return Projectile
