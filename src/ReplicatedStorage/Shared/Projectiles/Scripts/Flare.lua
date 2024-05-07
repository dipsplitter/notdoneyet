local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")
local Projectile = Framework.GetShared("Projectile")
local InstanceUtilities = Framework.GetShared("InstanceUtilities")

local AreaOfEffect = Framework.GetServer("AreaOfEffect")
local VisualsReplicator = Framework.GetServer("VisualsReplicator")
local DamageService = Framework.GetServer("DamageService")
local CharacterRegistry = Framework.GetServer("CharacterRegistry")

-- TEMP
local StatusEffectService = Framework.GetServer("StatusEffectService")

local Flare = {
	
	Default = {
		DamageProperties = {
			DamageType = "Fire",
			BaseDamage = 45,
		
			StatusEffects = {
				Burning = {},
			},
		},
		
		BurningParams = {
			
		},

		VerticalVelocity = 5,
		HorizontalVelocity = 140,

		GravityScale = 0.75,
		ImpulseIgnoresMass = true,
	}
	
}

local function OnDirectHit(self, character)
	character = CharacterRegistry.GetCharacterFromModel(character)

	local damageArgs = {
		Target = character,
		Attacker = self:GetCurrentOwner(),

		Inflictor = self,
	}

	if StatusEffectService.GetEffect(character, "Burning") then
		damageArgs.ForceFlags = {
			Critical = true,
		}
	end

	local results = DamageService.DealDamage(damageArgs)

	StatusEffectService.Apply({
		Name = "Burning",
		Source = self,
		Target = character,
	})
end

function Flare.Create(params)
	params.Id = params.Id or "Flare"
	local projectile = Projectile.new(params)
	
	projectile.OverlapParams = OverlapParams.new()
	projectile.OverlapParams.FilterDescendantsInstances = {projectile.Model}
	
	projectile.OnDirectHit = OnDirectHit
	
	projectile:AddConnections({
		Touched = projectile:ConnectTo("Touched", function(parts)
			projectile.CanTouch = false
			
			local hitCharacter = InstanceUtilities.GetCharacterAncestor(parts[1])
			if hitCharacter then
				projectile:OnDirectHit(hitCharacter)
			end
			
			projectile:ScheduleForDeletion()
		end),
	})
	
	return projectile
end


return Flare
