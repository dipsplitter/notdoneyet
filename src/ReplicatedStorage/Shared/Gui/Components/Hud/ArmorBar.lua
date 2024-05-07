local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local UiFramework = Framework.GetShared("UiFramework")
local HudUtilities = Framework.GetShared("HudUtilities")
local GetSchemeGlobal = Framework.GetShared("GetSchemeGlobal")

local RESOURCE = UiFramework.GetResource("ArmorBar")
local ValueBar = UiFramework.GetElement("ValueBar")
local CharacterAttributeBar = UiFramework.GetComponent("CharacterAttributeBar")

local armorBarUi = UiFramework.CreateComponent(RESOURCE)

local function Update(valueBar, armor, maxArmor)
	local components = valueBar.Components
	local transparencyGradient = components.ArmorImage.UIGradient
	
	local armorRatio = armor / maxArmor
	local sizeRatio = math.clamp(1 - armorRatio, 0, 1)
	transparencyGradient.Offset = Vector2.new(sizeRatio, sizeRatio)
	
	UiFramework.SetText("%Armor%", armor)
	UiFramework.SetText("%MaxArmor%", maxArmor)
	
	if armorRatio < RESOURCE.Config.LowArmorThreshold then	
		if not valueBar:IsAnimationActive("LowArmorPulse") then
			valueBar:Animate("LowArmorPulse")
		end
	else
		valueBar:Animate("StopLowArmorPulse")
	end
end

local function UpdateAbsorption(valueBar, absorption)
	local components = valueBar.Components
	local absorptionLabel = components.ArmorAbsorptionDisplay

	local number = math.floor(absorption * 100)
	
	UiFramework.SetText("%Absorption%", `{number}%`)
	
	for i, data in RESOURCE.Config.AbsorptionRanges do
		local range = data.Range
		if number >= range[1] and number < range[2] then
			
			local armorImage = components.ArmorImage
			armorImage.BackgroundColor3 = GetSchemeGlobal.Typed(RESOURCE, "Colors", data.Color)
			
		end
	end
end

local ArmorBar = {}
ArmorBar.__index = ArmorBar

function ArmorBar.new(params)
	local self = {
		Object = ValueBar.new(params)
	}
	setmetatable(self, ArmorBar)
	
	self.Object:SetSizeRatioComponents("Armor", "MaxArmor")
	
	return self
end

function ArmorBar:OnHudInitialize()
	CharacterAttributeBar.AddValue(self.Object, "Armor", Update)
	CharacterAttributeBar.AddValue(self.Object, "ArmorAbsorption", UpdateAbsorption)
	
	self.Object.Ui.Visible = true
end

function ArmorBar:OnClientDeath()
	CharacterAttributeBar.OnClientDeath(self.Object)
end

local UiComponent_ArmorBar = {}

function UiComponent_ArmorBar.Create()
	HudUtilities.SetParent(armorBarUi, RESOURCE)
	
	local component = ArmorBar.new({
		Resource = RESOURCE,
		Ui = armorBarUi,
	})
	UiComponent_ArmorBar.Object = component
	return component
end

function UiComponent_ArmorBar.OnSchemeReload()

end

return UiComponent_ArmorBar 