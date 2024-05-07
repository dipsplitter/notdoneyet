local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local UiFramework = Framework.GetShared("UiFramework")
local HudUtilities = Framework.GetShared("HudUtilities")

local Client = Framework.GetClient("Client")

local RESOURCE = UiFramework.GetResource("HealthBar")
local ValueBar = UiFramework.GetElement("ValueBar")
local CharacterAttributeBar = UiFramework.GetComponent("CharacterAttributeBar")

local healthBarUi = UiFramework.CreateComponent(RESOURCE)

local function Update(valueBar, health, maxHealth)
	local components = valueBar.Components
	local transparencyGradient = components.HealthImage.UIGradient
	
	local healthRatio = health / maxHealth
	local sizeRatio = math.clamp(1 - healthRatio, 0, 1)
	transparencyGradient.Offset = Vector2.new(sizeRatio, sizeRatio)
	
	UiFramework.SetText("%Health%", health)
	UiFramework.SetText("%MaxHealth%", maxHealth)
	
	if healthRatio < RESOURCE.Config.LowHealthThreshold then	
		if not valueBar:IsAnimationActive("LowHealthPulse") then
			valueBar:Animate("LowHealthPulse")
		end
	else
		valueBar:Animate("StopLowHealthPulse")
	end
end

local HealthBar = {}
HealthBar.__index = HealthBar

function HealthBar.new(params)
	local self = {
		Object = ValueBar.new(params)
	}
	setmetatable(self, HealthBar)
	
	self.Object:SetSizeRatioComponents("Health", "MaxHealth")
	
	return self
end

function HealthBar:OnHudInitialize()
	CharacterAttributeBar.AddValue(self.Object, "Health", Update)
	self.Object.Ui.Visible = true
end

function HealthBar:OnClientDeath()
	CharacterAttributeBar.OnClientDeath(self.Object)
end

local UiComponent_HealthBar = {}

function UiComponent_HealthBar.Create()
	HudUtilities.SetParent(healthBarUi, RESOURCE)
	
	local component = HealthBar.new({
		Resource = RESOURCE,
		Ui = healthBarUi,
	})
	UiComponent_HealthBar.Object = component
	return component
end

function UiComponent_HealthBar.OnSchemeReload()

end

return UiComponent_HealthBar 