local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local WeaponAttacks = Framework.GetShared("WeaponAttacks")
local ActionManagerConnector = Framework.GetShared("ActionManagerConnector")
local MeleeWeapon = Framework.GetShared("MeleeWeapon")

local BaseTool = if Framework.IsClient then Framework.GetClient("BaseTool") else Framework.GetServer("BaseTool")

local IT_Melee = {}
IT_Melee.__index = IT_Melee
IT_Melee.ClassName = "IT_Melee"

setmetatable(IT_Melee, BaseTool)

function IT_Melee.new(params)
	local self = BaseTool.new(params)
	setmetatable(self, IT_Melee)

	MeleeWeapon.AddRaycaster(self)
	MeleeWeapon.ConnectMeleeAttack(self, "Primary") 

	local actionManager = self:GetActionManager()
	local action = actionManager:GetAction("Primary")

	self:AddConnections({
		OnEquip = actionManager:GetActionStartedSignal("Equip"):Connect(function()
			self.Animator:Play("Equip")
			self.Animator:Play("Idle")
			self.Sounds:PlaySound("Equip")
		end),

		OnEquipFinished = actionManager:GetActionEndedSignal("Equip"):Connect(function()
			actionManager:Bind("Primary")
		end),

		OnAttack = actionManager:GetActionStartedSignal("Primary"):Connect(function()
			self.Animator:Play("Primary")
			self.Sounds:PlaySound("Swing")
		end),

		OnUnequip = actionManager:GetActionStartedSignal("Unequip"):Connect(function()
			self.Animator:StopAll()
			actionManager:Cancel("Primary")
			self.Sounds:StopAllSounds()
		end)
	})

	WeaponAttacks.SetActionAsAttack(self, "Primary")

	return self
end

return IT_Melee
