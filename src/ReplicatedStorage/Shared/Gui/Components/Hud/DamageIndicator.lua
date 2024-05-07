local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local UiFramework = Framework.GetShared("UiFramework")

local Client = Framework.GetClient("Client")

local RESOURCE = UiFramework.GetResource("DamageIndicator")
local CharacterBillboardIndicator = UiFramework.GetElement("CharacterBillboardIndicator")

-- The active DI template
local damageIndicatorCache = UiFramework.CreateComponent(RESOURCE)
local activeIndicators = {}

local DamageIndicator = {}
DamageIndicator.__index = DamageIndicator

function DamageIndicator.new(params)
	local self = {
		Flags = params.Flags,
		Object = CharacterBillboardIndicator.new(params),
		DamageTable = params.DamageTable,
		
		RemoveTask = nil
	}
	setmetatable(self, DamageIndicator)
	
	self:Update()
	
	return self
end

function DamageIndicator:UpdateText(displayType)
	local display = self.Object.Components[`{displayType}Display`]

	local text = display.Text
	local currentNumber = tonumber(text)
	
	if not currentNumber then
		display.Text = (-1 * self.DamageTable[displayType])
	else
		display.Text = (currentNumber - self.DamageTable[displayType])
	end
	
	display.Visible = true
end

function DamageIndicator:ScheduleRemoval()
	if self.RemoveTask then
		task.cancel(self.RemoveTask)
	end
	
	self.RemoveTask = task.delay(self.Object:GetConfig("BatchWindow"), function()
		if self.Object then
			activeIndicators[self.Object.Character] = nil
		end
		
		self:Destroy()
	end)
end

function DamageIndicator:Update(damageTable, flags)
	self.Object:UpdatePosition()
	self:ScheduleRemoval()
	
	if damageTable then
		self.DamageTable = damageTable
	end
	
	if flags then
		self.Flags = flags
	end
	
	-- Armor goes on top of health
	if self.Flags.Armor then
		self:UpdateText("Armor")
	end
	
	if self.Flags.Health then
		self:UpdateText("Health")
	end
	
	self.Object:Animate("Fadein")
end

function DamageIndicator:Destroy()
	if self.Object then
		self.Object:Destroy()
	end
	
	table.clear(self)
end

local UiComponent_DamageIndicator = {}

function UiComponent_DamageIndicator.Create(args)
	if Client.IsDead then
		return
	end
	
	local character = args.Instance
	local damageTable = args.DamageTable
	local flags = args.Flags
	
	local existingIndicator = activeIndicators[character]
	
	if existingIndicator then
		existingIndicator:Update(damageTable, flags)
	else
		local activeIndicator = damageIndicatorCache:Clone()
		activeIndicator.Parent = UiFramework.GetScreenGui(RESOURCE.ScreenGui or "Hud")
		
		activeIndicators[character] = DamageIndicator.new({
			Ui = activeIndicator,
			Character = character,
			Flags = flags,
			Resource = RESOURCE,
			DamageTable = damageTable
		})
	end
end

function UiComponent_DamageIndicator.OnSchemeReload()
	UiFramework.ApplyResource(damageIndicatorCache, RESOURCE)
end

-- Destroy everything on character death
Client.CharacterDiedSignal:Connect(function()
	for char, indicator in activeIndicators do
		indicator:Destroy()
		activeIndicators[char] = nil
	end
end)

return UiComponent_DamageIndicator
