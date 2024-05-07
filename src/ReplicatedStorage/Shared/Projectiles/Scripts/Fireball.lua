local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local Projectile = Framework.GetShared("Projectile")
local InstanceUtilities = Framework.GetShared("InstanceUtilities")

local AreaOfEffect = Framework.GetServer("AreaOfEffect")
local VisualsReplicator = Framework.GetServer("VisualsReplicator")
local DamageService = Framework.GetServer("DamageService")

-- TEMP
local StatusEffectService = Framework.GetServer("StatusEffectService")

local Fireball = {}

function Fireball.Create(params)
	params = params or {}
	params.Id = params.Id or "Fireball"
	
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
			
			-- TODO
			StatusEffectService.Apply({
				Name = "Burning",
				Source = self,
				Target = character,
				Params = {
					Duration = (results.Health.Total + results.Armor.Total) / 15
				}
			})
		end)
		VisualsReplicator.Replicate("FireballExplosion", {CFrame = self.Model:GetPivot()})

		self:ScheduleForDeletion()
	end
	
	projectile:AddConnections({
		Touched = projectile:ConnectTo("Touched", function(parts)
			if InstanceUtilities.GetCharacterAncestor(parts[1]) then
				projectile:Explode()
				return
			end

			if projectile.Lifetime < projectile:GetStat("ExplodeOnAnyTouchDelay") then
				return
			end

			projectile:Explode()
		end),
	})
	
	return projectile
end


return Fireball
