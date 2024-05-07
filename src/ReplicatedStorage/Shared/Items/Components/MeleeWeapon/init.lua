local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local WeaponAttacks = Framework.GetShared("WeaponAttacks")
local CharacterRaycaster = Framework.GetShared("CharacterRaycaster")
local MeleeHitbox = Framework.GetShared("MeleeHitbox")

local ClientRaycaster = Framework.GetClient("ClientRaycaster")

local DamageService = Framework.GetServer("DamageService")

local DEFAULT_RANGE = 7

local MeleeWeapon = {}

function MeleeWeapon.AddRaycaster(item)
	if Framework.IsClient then
		
		item.MeleeRaycaster = ClientRaycaster.new({
			CollisionGroup = "Projectile",
		})
		
	elseif Framework.IsServer then
		
		item.MeleeRaycaster = CharacterRaycaster.new({
			Character = item.Character,
			CollisionGroup = "Projectile",
		})
		
	end
end

function MeleeWeapon.AddHitbox(item)
	MeleeHitbox.CreateHitbox(item)
end

function MeleeWeapon.GetDamageFunction(actionName, callbacks)
	callbacks = callbacks or {}
	
	local customInflictorInfo = callbacks.InflictorInfo
	local targetFilter = callbacks.PreFilter
	local preCallback = callbacks.PreDamage
	local damageCallback = callbacks.Damage
	local postCallback = callbacks.PostDamage
	
	return function(item, args)
		if not args then
			return
		elseif not args.Args then
			return
		end
		
		local raycastResults = args.Args
		for i, result in raycastResults do

			local target = result.Character
			
			-- Check filter if there is one
			if targetFilter and not targetFilter(target) then
				continue
			end
		
			if preCallback then
				preCallback(target, item)
			end
			
			if damageCallback then
				damageCallback(target, item, customInflictorInfo)
			else
				MeleeWeapon.DealMeleeDamage(item, actionName, target, customInflictorInfo)
			end

			if postCallback then
				postCallback(target, item)
			end
		end
		
	end
end

function MeleeWeapon.Raycast(item, actionName, finishedCallback)
	local actionManager = item:GetActionManager()
	local action = actionManager:GetAction(actionName)
	local range = action:GetConfig("MaxRange") or DEFAULT_RANGE

	local results

	if Framework.IsClient then

		results = item.MeleeRaycaster:CastToMouse(range)

		if not results then
			results = item.MeleeRaycaster:BlockcastToMouse(range)
		end

	elseif Framework.IsServer then

		results = item.MeleeRaycaster:CastFromHead(range)

		if not results then
			results = item.MeleeRaycaster:BlockcastFromCenter(range)
		end
	end
	
	if finishedCallback then
		finishedCallback(results)
	end
	
	return results
end

function MeleeWeapon.ReplicateRaycast(item, actionName, results)
	if not results then
		WeaponAttacks.StartAttack(item, actionName, results)
	else
		results.SIGNATURE = "MultiCharacterRaycastResult"

		WeaponAttacks.ReplicateAttack(item, actionName, results)
	end
end

function MeleeWeapon.DealMeleeDamage(item, actionName, target, inflictorInfoCallback)
	if Framework.IsClient then
		return
	end
	
	local action = item:GetActionManager():GetAction(actionName)

	local damageArgs = {
		Target = target,
		Attacker = item:GetCharacterOwner(),

		Inflictor = item,
		InflictorInfo = if inflictorInfoCallback then inflictorInfoCallback(item) else {Action = actionName}
	}

	return DamageService.DealDamage(damageArgs)
end

return MeleeWeapon
