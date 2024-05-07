local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")

local Players = game:GetService("Players")

local ProjectileNetworker = {}
ProjectileNetworker.__index = ProjectileNetworker
ProjectileNetworker.ClassName = "ProjectileNetworker"
setmetatable(ProjectileNetworker, BaseClass)

function ProjectileNetworker.new(projectile)
	local self = BaseClass.new()
	setmetatable(self, ProjectileNetworker)
	
	self:InjectObject("Projectile", projectile)
	
	self.Active = false
	self:SetNewOwner()
	
	self:AddConnections({
		
	})

	return self
end

function ProjectileNetworker:SetNewOwner(newOwner)
	local player = if newOwner then Players:GetPlayerFromCharacter(newOwner) else self.Projectile:GetCurrentOwnerPlayer()
end

function ProjectileNetworker:ClientInitiatedTouchEvent(part)
	self.Projectile:FireSignal("Touched", part)
end

function ProjectileNetworker:ClientInitiatedEvent(eventName, ...)
	if self.Projectile:GetSignal(eventName) then
		self.Projectile:FireSignal(eventName, ...)
	else
		self.Projectile:FireSignal("Event", ...)
	end
end

function ProjectileNetworker:ClientInitiatedDestroy()
	-- Check if we can destroy
	self.Projectile:Destroy()
end

function ProjectileNetworker:ServerInitiatedDestroy()
	self.Projectile:Destroy()
end

return ProjectileNetworker
