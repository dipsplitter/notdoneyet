local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local UiFramework = Framework.GetShared("UiFramework")
local EnumService = Framework.GetShared("EnumService")
local LayoutParser = Framework.GetShared("LayoutParser")
local Signal = Framework.GetShared("Signal")
local Enum_Classes = EnumService.GetEnum("Classes")

local Client = Framework.GetClient("Client")

local BaseMenu = UiFramework.GetElement("BaseMenu")
local LAYOUT = UiFramework.GetLayout("ClassSelectionMenu")
LayoutParser.Apply(LAYOUT)

local classChosenSignal = Signal.new()
local screenGui = UiFramework.GetScreenGui("ClassSelectionMenu")

-- Buttons
local ClassSelectButton = UiFramework.GetComponent("ClassSelectButton")
ClassSelectButton.SetClassChosenSignal(classChosenSignal)

local ClassDescription = UiFramework.GetComponent("ClassDescription")

local ClassSelection = BaseMenu.new(screenGui, Enum.KeyCode.Comma)

local classButtons = {}
local chosenClassButton = nil
local lockedClassButton = nil

for className, id in Enum_Classes do
	if type(id) == "function" then
		continue
	end
	
	classButtons[className] = ClassSelectButton.Create(className)
end
ClassDescription.SetClass()

classChosenSignal:Connect(function(className, lockedIn)
	if chosenClassButton and chosenClassButton.Class ~= className then
		chosenClassButton:ResetState()
	end
	
	if lockedIn and lockedClassButton and lockedClassButton.Class ~= className then
		lockedClassButton:ResetState()
	end
	
	-- We stopped selecting anything
	if not className then
		chosenClassButton = nil
		return
	end
	
	-- Request to play as this class
	if lockedIn then
		Client.RequestSetClass(className)
		lockedClassButton = classButtons[className]
		
		if chosenClassButton and chosenClassButton.Class == className then
			chosenClassButton = nil
		end
	else -- Set this to the chosen class
		chosenClassButton = classButtons[className]
	end
	
	ClassDescription.SetClass(className)
end)

return ClassSelection
