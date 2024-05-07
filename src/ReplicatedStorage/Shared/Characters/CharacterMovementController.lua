local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Framework = require(ReplicatedStorage.Framework)
local TableUtilities = Framework.GetShared("TableUtilities")
local Globals = Framework.GetShared("Globals")

local EPSILON = 1e-3

local IsClient = RunService:IsClient()
local localPlayer = Players.LocalPlayer

local camera = workspace.CurrentCamera

local CONTROLS = {
	Up = Enum.KeyCode.W,
	Left = Enum.KeyCode.A,
	Right = Enum.KeyCode.D,
	Down = Enum.KeyCode.S,
	
	Jump = Enum.KeyCode.Space,
}

local BASE_MOVEMENT_SETTINGS = {
	AutoBunnyHop = false,
	Friction = 6,
	AirFriction = 0.5,
	AirControl = 0.3,
	
	-- These are only used for air strafing
	Strafe = {
		MaxSpeed = 1,
		Acceleration = 110,
	},
	
	Ground = {
		MaxSpeed = 16,
		Acceleration = 7,
		Deceleration = 7,
	},
	
	Air = {
		MaxSpeed = 16,
		Acceleration = 3,
		Deceleration = 3,
	},
}

local CharacterMovementController = {}
CharacterMovementController.__index = CharacterMovementController

function CharacterMovementController.new(characterModel, inputHandler, movementSettings)
	local self = {
		Model = nil,
		Humanoid = nil,
		Camera = nil,
		
		Velocity = Vector3.zero,
		
		-- X: horizontal, Z: vertical (forward/backward), Y: always 0
		InputDirection = Vector3.zero,
		
		InputHandler = inputHandler,
		
		JumpQueued = false,
		
		PreSimulationConnection = nil,
		
		MovementSettings = if movementSettings then TableUtilities.Reconcile(movementSettings, BASE_MOVEMENT_SETTINGS) else BASE_MOVEMENT_SETTINGS,
	}
	setmetatable(self, CharacterMovementController)
	
	if characterModel then
		self:SetCharacter(characterModel)
	end
	
	return self
end

function CharacterMovementController:SetCharacter(character)
	self.Model = character
	self.Humanoid = character:WaitForChild("Humanoid")
	self.Camera = if IsClient then camera else character.PrimaryPart.EyesAttachment
	
	self.Velocity = Vector3.zero
	self.InputDirection = Vector3.zero
	
	self.JumpQueued = false
end

function CharacterMovementController:GetCameraCFrame()
	if IsClient then
		return self.Camera.CFrame
	end
	
	-- Attachment for NPCs
	return self.Camera.WorldCFrame
end

function CharacterMovementController:Start()
	if self.PreSimulationConnection then
		return
	end
	
	-- Client uses RenderStepped, server uses Stepped
	local runServiceEvent = if IsClient then RunService.PreSimulation else RunService.PreAnimation

	self.PreSimulationConnection = runServiceEvent:Connect(function(dt)
		if not self.Model or not self.Humanoid then
			return
		end

		if self.Humanoid.Health == 0 then
			return
		end
		
		self:Update(dt)
	end)
end

function CharacterMovementController:UpdateInputDirection()
	local vertical, horizontal = 0, 0
	
	if self.InputHandler:IsHeld(CONTROLS.Up) then
		vertical -= 1
	end
	
	if self.InputHandler:IsHeld(CONTROLS.Down) then
		vertical += 1
	end
	
	if self.InputHandler:IsHeld(CONTROLS.Left) then
		horizontal -= 1
	end
	
	if self.InputHandler:IsHeld(CONTROLS.Right) then
		horizontal += 1
	end
	
	self.InputDirection = Vector3.new(horizontal, 0, vertical)
end

function CharacterMovementController:Update(dt)
	if not self.Model or not self.Humanoid then
		return
	end
	
	if not self.Model.PrimaryPart then
		return
	end
	
	self:UpdateInputDirection()
	
	self:QueueJump()
	
	if self:IsGrounded() then
		self:HandleGroundMovement(dt)
	else
		self:HandleAirMovement(dt)
	end
	
	local moveDirection = Vector3.zero
	if self.Velocity ~= Vector3.zero then
		moveDirection = self.Velocity.Unit
	end
	local humanoidWalkSpeed = self.Velocity.Magnitude
	
	self.Humanoid.WalkSpeed = humanoidWalkSpeed
	self.Humanoid:Move(moveDirection, false)
end

function CharacterMovementController:QueueJump()
	if self.MovementSettings.AutoBunnyHop then
		self.JumpQueued = self.InputHandler:IsHeld(CONTROLS.Jump)
		return
	end
	
	if self.InputHandler:WasJustPressed(CONTROLS.Jump) and not self.JumpQueued then
		self.JumpQueued = true
	end
	
	if self.InputHandler:WasJustReleased(CONTROLS.Jump) then
		self.JumpQueued = false
	end
end

function CharacterMovementController:IsGrounded()
	-- Rampslide check
	if self.Model.PrimaryPart.AssemblyLinearVelocity.Y > 50 then
		return false
	end
	
	return self.Humanoid.FloorMaterial ~= Enum.Material.Air
end

function CharacterMovementController:ApplyImpulse(impulse, baseVolumeScale)
	self.Velocity = Vector3.new(self.Velocity.X + impulse.X, 0, self.Velocity.Z + impulse.Z)
	
	-- Multiply by the volume constant because ApplyImpulse requires some massive numbers to make anything move
	self.Model.PrimaryPart:ApplyImpulse(Vector3.new(0, impulse.Y * (baseVolumeScale or Globals.DefaultBoundingBoxVolume), 0))
end

function CharacterMovementController:HandleAirMovement(dt)
	if self.InputDirection.Z ~= 0 then
		self:ApplyFriction(1, true, dt)
	end
	
	local airSettings = self.MovementSettings.Air
	
	local wishDirection = self:GetCameraCFrame():VectorToWorldSpace(self.InputDirection)
	wishDirection = Vector3.new(wishDirection.X, 0, wishDirection.Z)
	
	local wishSpeed = wishDirection.Magnitude
	wishSpeed *= airSettings.MaxSpeed
	
	-- No NaNs !!!
	if wishDirection ~= Vector3.zero then
		wishDirection = wishDirection.Unit
	end

	local airControlWishSpeed = wishSpeed
	
	local acceleration
	if self.Velocity:Dot(wishDirection) < 0 then
		acceleration = airSettings.Acceleration
	else
		acceleration = airSettings.Deceleration
	end
	
	-- If we are only strafing (no holding W), use the strafe settings instead
	if self.InputDirection.X ~= 0 and self.InputDirection.Z == 0 then
		local maxStrafeSpeed = self.MovementSettings.Strafe.MaxSpeed
		if wishSpeed > maxStrafeSpeed then
			wishSpeed = maxStrafeSpeed
		end
		
		acceleration = self.MovementSettings.Strafe.Acceleration
	end
	
	self:Accelerate(wishDirection, wishSpeed, acceleration, dt)
	
	if self.MovementSettings.AirControl > 0 then
		self:ApplyAirControl(wishDirection, airControlWishSpeed, dt)
	end
end

function CharacterMovementController:ApplyAirControl(targetDirection, targetSpeed, dt)
	if math.abs(self.InputDirection.Z) < EPSILON or math.abs(targetSpeed) < EPSILON then
		return
	end
	
	local currentSpeed = self.Velocity.Magnitude
	
	local normalizedVelocity = if self.Velocity ~= Vector3.zero then self.Velocity.Unit else Vector3.zero
	local dot = normalizedVelocity:Dot(targetDirection)
	
	local k = 64 -- ????
	k *= self.MovementSettings.AirControl * dot * dot * dt
	
	local xVel, zVel = normalizedVelocity.X, normalizedVelocity.Z
	
	if (dot > 0) then
		xVel *= currentSpeed + targetDirection.X * k
		zVel *= currentSpeed + targetDirection.Z * k
		
		local tempVector = Vector3.new(xVel, 0, zVel).Unit
		
		xVel = tempVector.X
		zVel = tempVector.Z
	end
	
	self.Velocity = Vector3.new(xVel * currentSpeed, 0, zVel * currentSpeed)
end

function CharacterMovementController:HandleGroundMovement(dt)
	-- No friction if we're about to jump
	self:ApplyFriction(if self.JumpQueued then 0 else 1, false, dt)
	
	local groundSettings = self.MovementSettings.Ground
	
	local wishDirection = self:GetCameraCFrame():VectorToWorldSpace(self.InputDirection)
	wishDirection = Vector3.new(wishDirection.X, 0, wishDirection.Z)
	
	if wishDirection ~= Vector3.zero then
		wishDirection = wishDirection.Unit
	end

	local wishSpeed = wishDirection.Magnitude
	wishSpeed *= groundSettings.MaxSpeed
	
	self:Accelerate(wishDirection, wishSpeed, groundSettings.Acceleration, dt)
	
	if self.JumpQueued then
		self.Humanoid.Jump = true
		self.JumpQueued = false
	end
end

function CharacterMovementController:ApplyFriction(multiplier, isInAir, dt)
	local currentVelocity = Vector3.new(self.Velocity.X, 0, self.Velocity.Z)
	local currentSpeed = currentVelocity.Magnitude
	
	local drop = 0
	local frictionValue = if isInAir then self.MovementSettings.AirFriction else self.MovementSettings.Friction
	
	local control = if currentSpeed < self.MovementSettings.Ground.Deceleration then self.MovementSettings.Ground.Deceleration else currentSpeed
	drop = control * frictionValue * dt * multiplier
	
	local newSpeed = currentSpeed - drop
	
	if newSpeed < 0 then
		newSpeed = 0
	end
	
	if currentSpeed > 0 then
		newSpeed /= currentSpeed
	end

	local xVel = self.Velocity.X * newSpeed
	local zVel = self.Velocity.Z * newSpeed
	self.Velocity = Vector3.new(xVel, 0, zVel)
end

function CharacterMovementController:Accelerate(targetDirection, targetSpeed, acceleration, dt)
	local currentSpeed = self.Velocity:Dot(targetDirection)
	local addSpeed = targetSpeed - currentSpeed
	
	if addSpeed <= 0 then
		return
	end
	
	local acceleratedSpeed = targetSpeed * dt * acceleration
	if acceleratedSpeed > addSpeed then
		acceleratedSpeed = addSpeed
	end
	
	local xVel = self.Velocity.X + acceleratedSpeed * targetDirection.X
	local zVel = self.Velocity.Z + acceleratedSpeed * targetDirection.Z
	
	self.Velocity = Vector3.new(xVel, 0, zVel)
end

function CharacterMovementController:Destroy()
	self.PreSimulationConnection:Disconnect()
	
	table.clear(self)
	setmetatable(self, nil)
	table.freeze(self)
end

return CharacterMovementController
