local GuiObject = require(script.Parent.GuiObject)

local PositionTemplate = script.Position

local CharacterBillboardIndicator = {}
CharacterBillboardIndicator.__index = CharacterBillboardIndicator
CharacterBillboardIndicator.ClassName = "CharacterBillboardIndicator"
setmetatable(CharacterBillboardIndicator, GuiObject)

function CharacterBillboardIndicator.new(params)
	local self = GuiObject.new(params)
	setmetatable(self, CharacterBillboardIndicator)
	
	self.Character = params.Character
	self.Pin = params.Pin
	
	self.PositionPart = PositionTemplate:Clone()
	self.PositionPart.Parent = workspace.Visuals
	
	return self
end

function CharacterBillboardIndicator:UpdatePosition(object)
	if object and object:IsA("Model") then
		object = object.PrimaryPart
	else
		object = self.Character:FindFirstChild("Head") or self.Character.PrimaryPart
	end
	local position = object.Position
	
	if self.Pin then
		self.Ui.Adornee = object
	else
		self.PositionPart.Position = position
		self.Ui.Adornee = self.PositionPart
	end

	self.Ui.Enabled = true
end

function CharacterBillboardIndicator:Destroy()
	self.PositionPart:Destroy()
	GuiObject.Destroy(self)
end

return CharacterBillboardIndicator