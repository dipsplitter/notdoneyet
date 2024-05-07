local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local Projectile = Framework.GetShared("Projectile")
local InstanceUtilities = Framework.GetShared("InstanceUtilities")

local AreaOfEffect = Framework.GetServer("AreaOfEffect")
local VisualsReplicator = Framework.GetServer("VisualsReplicator")
local DamageService = Framework.GetServer("DamageService")

local Rocket = {
	Default = {
		BlastRadius = 9,

		DamageProperties = {
			DamageType = "Blast",
			BaseDamage = 80,

			DistanceModifiers = {
				Max = 1.25,
				Min = 0.5,

				MaxDistance = 10,
				MinDistance = 100,
			},

			SplashModifiers = {
				Min = 0.5,
				MaxDistance = 2,
				MinDistance = 8,
			},
			
			SelfDamageScale = 0.3,
			
			KnockbackProperties = {
				SelfDamageScale = 4,
			},
		},

		HorizontalVelocity = 70,

		ImpulseIgnoresMass = true,
	}
}

function Rocket.Create(params)
	params.Id = params.Id or "Rocket"
	local projectile = Projectile.new(params)

	projectile.OverlapParams = OverlapParams.new()
	projectile.OverlapParams.FilterDescendantsInstances = {projectile.Model}

	projectile.Explode = function(self)
		local explosion = AreaOfEffect.new({
			Origin = self.Model:GetPivot().Position,
			QueryParams = {
				Size = self:GetStat("BlastRadius"),
				["OverlapParams"] = self.OverlapParams,
			},
		})

		explosion:GetCharacters(function(character)
			return explosion:IsInLineOfSight(character)
		end)
		explosion:ForEachCharacter(function(character)

			local damageArgs = {
				Target = character,
				Attacker = self:GetCurrentOwner(),

				Inflictor = self,
			}

			local results = DamageService.DealDamage(damageArgs)
			if not results then
				return
			end
		end)
		VisualsReplicator.Replicate("FireballExplosion", {CFrame = self.Model:GetPivot()})

		self:ScheduleForDeletion()
	end

	projectile:AddConnections({
		Touched = projectile:ConnectTo("Touched", function(parts)
			projectile:Explode()
		end),
	})

	return projectile
end

return Rocket
