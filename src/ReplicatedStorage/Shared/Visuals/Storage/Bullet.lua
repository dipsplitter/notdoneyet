local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local VisualEffect = Framework.GetShared("VisualEffect")

local RunService = game:GetService("RunService")

local Bullet = {}
Bullet.__index = Bullet
Bullet.ClassName = "BulletVisual"
setmetatable(Bullet, VisualEffect)

function Bullet.new(folder, params)
	local self = VisualEffect.new(folder, params)
	setmetatable(self, Bullet)
	
	self.Character = params.Character
	self.FireAttachment = self.Character:FindFirstChild("FireAttachment", true)
	
	if not self.FireAttachment then
		self.FireAttachment = params.Model:FindFirstChild("FireAttachment", true)
	end
	
	local origin = self.FireAttachment.WorldPosition
	local direction = self.Character.PrimaryPart.EyesAttachment.WorldCFrame.LookVector
	local spawnCframe = CFrame.lookAt(origin, origin + direction * 100)
	
	self.Base:PivotTo(spawnCframe)
	
	-- Mover
	local linearVelocity = self.Base:FindFirstChild("LinearVelocity", true)
	linearVelocity.MaxForce = math.huge
	linearVelocity.VectorVelocity = spawnCframe.LookVector * 250
	linearVelocity.Enabled = true
	
	local length = self.Base:GetExtentsSize().Z
	self:AddConnections({	
		Collision = self.Base.BoundingBox.Touched:Connect(function(other)
			if other:IsDescendantOf(self.Character) then
				return
			end
			
			self.Base:Destroy()
		end),
		
		--[[
		Collision = RunService.Heartbeat:Connect(function(dt)
			local pivot = self.Base:GetPivot()
			--local originOffset = Vector3.new(0, 0, -length / 2)
			local endPosition = pivot.Position + (self.Base.PrimaryPart.AssemblyLinearVelocity * dt)
			local result = workspace:Raycast(pivot.Position, endPosition)
			
			if not result then
				return
			end
			
			
		end)
		]]
	})
	
	return self
end

return Bullet
