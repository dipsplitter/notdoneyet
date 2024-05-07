local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local WeaponAttacks = Framework.GetShared("WeaponAttacks")
local CharacterRaycaster = Framework.GetShared("CharacterRaycaster")
local SpreadPattern = Framework.GetShared("SpreadPattern")

local ClientRaycaster = Framework.GetClient("ClientRaycaster")
local Client = Framework.GetClient("Client")

local DamageService = Framework.GetServer("DamageService")

local MAX_RANGE = 1000

local function GetCharacterLookDirection(char)
	return char.PrimaryPart.EyesAttachment.WorldCFrame.LookVector * 500
end

local function AddSignatureToRaycastResult(result)
	result.SIGNATURE = "MultiCharacterRaycastResult"
end

local function GetCenterDirection(character)
	if Framework.IsClient then
		local mouseRay = Client.GetHeadToMouseRay()

		return CFrame.lookAt(Vector3.zero, mouseRay.Direction)
	end
	
	return CFrame.lookAt(Vector3.zero, GetCharacterLookDirection(character))
end

local HitscanWeapon = {}

function HitscanWeapon.AddRaycaster(item)
	local args = {
		CollisionGroup = "Hitscan",
		DefaultRange = MAX_RANGE
	}
	
	if Framework.IsClient then
		
		item.HitscanRaycaster = ClientRaycaster.new(args)
		
	elseif Framework.IsServer then
		
		args.Character = item.Character
		item.HitscanRaycaster = CharacterRaycaster.new(args)

	end
	
	item.HitscanRaycaster.DebugMode = true
end

function HitscanWeapon.SetActionAsAttack(item, actionName)
	local action = item:GetActionManager():GetAction(actionName)
	
	if action:GetConfig("SpreadRecovery") then
		action:SetConfig("LastAttackTime", 0)
		action:SetConfig("ConsecutiveAttacks", 1)
	end
	
	WeaponAttacks.SetActionAsAttack(item, actionName)
end

function HitscanWeapon.Attack(item, actionName)
	local actionManager = item:GetActionManager()
	local action = actionManager:GetAction(actionName)
	local range = action:GetConfig("MaxRange") or MAX_RANGE
	
	local results = item.HitscanRaycaster:CastToMouse(range)

	WeaponAttacks.ReplicateAttack(item, actionName, results)
end

function HitscanWeapon.GetRandomSpreadRange(item, actionName)
	local action = item:GetActionManager():GetAction(actionName)

	local minSpread, maxSpread = action:GetConfig("MinSpread") or 0, action:GetConfig("MaxSpread")

	-- Spread recovery
	if action:GetConfig("SpreadRecovery") then

		local consecutiveSpreadIncrease = action:GetConfig("ConsecutiveSpreadIncrease")

		local lastAttackTime = action:GetConfig("LastAttackTime")

		-- The spread recovery has finished; fire with the minimal spread
		if os.clock() - action:GetConfig("LastAttackTime") >= action:GetConfig("SpreadRecovery") then
			-- Reset increment
			if consecutiveSpreadIncrease then
				action:SetConfig("ConsecutiveAttacks", 0)
			end

			maxSpread = minSpread
		else
			action:SetConfig("ConsecutiveAttacks", action:GetConfig("ConsecutiveAttacks") + 1)
			local currentSpread = minSpread + consecutiveSpreadIncrease * action:GetConfig("ConsecutiveAttacks")
			maxSpread = math.min(maxSpread, currentSpread)
		end


		action:SetConfig("LastAttackTime", os.clock())
	end

	return minSpread, maxSpread
end

function HitscanWeapon.AttackWithRandomSpread(item, actionName, maxSpread, minSpread)
	local action = item:GetActionManager():GetAction(actionName)
	local minSpread, maxSpread = HitscanWeapon.GetRandomSpreadRange(item, actionName)
	local random = Random.new()
	local range = action:GetConfig("MaxRange") or MAX_RANGE
	
	local cframeDirection = GetCenterDirection(item.Character)
	
	local spreadDirection = CFrame.fromOrientation(0, 0, random:NextNumber(0, 2 * math.pi))
	local spreadAngle = CFrame.fromOrientation(random:NextNumber(minSpread or 0, maxSpread or 0), 0, 0)
	local lookVector = (cframeDirection * spreadDirection * spreadAngle).LookVector
	
	local results = nil
	if Framework.IsServer then
		results = item.HitscanRaycaster:CastFromHead(range, lookVector)
	else
		results = item.HitscanRaycaster:CastFromEyes(lookVector, range)
	end
	
	if not results then
		WeaponAttacks.StartAttack(item, actionName, results)
	else
		results.SIGNATURE = "MultiCharacterRaycastResult"

		WeaponAttacks.ReplicateAttack(item, actionName, results)
	end
end

function HitscanWeapon.AttackWithFixedPattern(item, actionName)
	local action = item:GetActionManager():GetAction(actionName)
	local range = action:GetConfig("MaxRange") or MAX_RANGE

	local cframeDirection = GetCenterDirection(item.Character)
	
	local directions = SpreadPattern.GenerateDirectionsArray(action, cframeDirection)
	
	local results = nil
	if Framework.IsServer then
		results = item.HitscanRaycaster:CastFromHead(range, directions)
	else
		results = item.HitscanRaycaster:CastFromEyes(directions, range)
	end
	
	if not results then
		WeaponAttacks.StartAttack(item, actionName, results)
	else
		results.SIGNATURE = "MultiCharacterRaycastResult"

		WeaponAttacks.ReplicateAttack(item, actionName, results)
	end
end

function HitscanWeapon.DealDamage(item, actionName, target)
	if Framework.IsClient then
		return
	end
	
	local action = item:GetActionManager():GetAction(actionName)

	local damageArgs = {
		Target = target,
		Attacker = item:GetCharacterOwner(),
		
		Inflictor = item,
		InflictorInfo = {Action = actionName}
	}
	
	return DamageService.DealDamage(damageArgs)
end

return HitscanWeapon
