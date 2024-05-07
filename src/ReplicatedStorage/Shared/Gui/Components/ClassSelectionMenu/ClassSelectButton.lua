local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local UiFramework = Framework.GetShared("UiFramework")
local EnumService = Framework.GetShared("EnumService")
local AssetService = Framework.GetShared("AssetService")
local Enum_Classes = EnumService.GetEnum("Classes")

local GuiButton = UiFramework.GetElement("GuiButton")

local Client = Framework.GetClient("Client")

local RESOURCE = UiFramework.GetResource("ClassSelectButton")
local classButtonTemplate = UiFramework.CreateComponent(RESOURCE)
local parent = UiFramework.GetScreenGui("ClassSelectionMenu").ClassButtons

local classChosenSignal = nil

local ClassSelectButton = {}
ClassSelectButton.__index = ClassSelectButton

function ClassSelectButton.new(params)
	local self = {
		Object = GuiButton.new(params)
	}
	setmetatable(self, ClassSelectButton)
	
	self.Class = params.ClassName
	
	self.Object.Ui.Name = self.Class
	self.Object.Ui.LayoutOrder = Enum_Classes[self.Class]
	self.Object.Ui.Image = AssetService.Images(`Classes.Icons.{self.Class}`).Id
	
	self.TimesClicked = 0
	
	self.Object:SetHoverCallback(function()
		
	end)
	
	self.Object:SetLeaveCallback(function()
		
	end)
	
	self.Object:SetInputCallbacks({
		MouseButton1Down = function()
			self.TimesClicked += 1
			
			-- Click once: highlight the button and display class information
			if self.TimesClicked == 1 then
				self.Object:SetState("Clicked")
				classChosenSignal:Fire(self.Class)
			else -- Click twice: play as the class
				self.Object:SetState("Chosen")
				classChosenSignal:Fire(self.Class, true)
			end
		end,
	})
	
	return self
end

function ClassSelectButton:ResetState()
	self.TimesClicked = 0
	self.Object:SetState()
end

local UiComponent_ClassSelectButton = {}

function UiComponent_ClassSelectButton.Create(className)
	local newButton = classButtonTemplate:Clone()

	local component = ClassSelectButton.new({
		Resource = RESOURCE,
		Ui = newButton,
		ClassName = className,
	})
	newButton.Parent = parent
	
	return component
end

function UiComponent_ClassSelectButton.SetClassChosenSignal(signal)
	classChosenSignal = signal
end

return UiComponent_ClassSelectButton
