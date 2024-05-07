local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")
local InputContext = Framework.GetShared("InputContext")

local InputHandler = {}
InputHandler.__index = InputHandler
InputHandler.ClassName = "InputHandler"
setmetatable(InputHandler, BaseClass)

function InputHandler.new(params)
	local self = BaseClass.new()
	setmetatable(self, InputHandler)
	
	self.Contexts = {}
	
	self.HeldInputs = {}
	
	self.PressedInputs = {}
	self.ReleasedInputs = {}
	
	self:AddSignals("InputBegan", "InputEnded", "InputOccurred")
	
	return self
end

function InputHandler:GetContext(contextName)
	return self.Contexts[contextName]
end

function InputHandler:CreateContext(contextParams)
	contextParams.InputHandler = self
	self.Contexts[contextParams.ContextName] = InputContext.new(contextParams)
end

function InputHandler:AddContext(context)
	self.Contexts[context.ContextName] = context
end

function InputHandler:RemoveContext(contextName)
	self.Contexts[contextName] = nil
end

function InputHandler:TriggerInput(params)
	local inputState = params.InputState
	local inputType = params.InputType
	
	if inputState == Enum.UserInputState.Begin then
		
		self.PressedInputs[inputType] = true
		task.delay(0, function()
			self.PressedInputs[inputType] = nil
		end)
		
		self.HeldInputs[inputType] = true
		self:FireSignal("InputBegan", params)
		self:FireSignal("InputOccurred", params)
		
	elseif inputState == Enum.UserInputState.End then
		
		if not self.HeldInputs[inputType] then
			return
		end

		self.HeldInputs[inputType] = nil
		
		-- Add to the just released list, and remove it the next cycle
		self.ReleasedInputs[inputType] = true
		task.delay(0, function()
			self.ReleasedInputs[inputType] = nil
		end)
		
		self:FireSignal("InputEnded", params)
		self:FireSignal("InputOccurred", params)
		
	end
end

function InputHandler:IsHeld(inputType)
	return self.HeldInputs[inputType] == true
end

function InputHandler:WasJustReleased(inputType)
	return self.ReleasedInputs[inputType] == true
end

function InputHandler:WasJustPressed(inputType)
	return self.PressedInputs[inputType] == true
end

--[[
	UserInputType, UserInputState and KeyCode enums
	Releases on next Heartbeat by default
]]
function InputHandler:Press(button, timeUntilRelease)
	timeUntilRelease = timeUntilRelease or 0

	self:TriggerInput({
		InputType = button,
		InputState = Enum.UserInputState.Begin,
	})
	
	task.delay(timeUntilRelease, function()
		self:Release(button)
	end)
end

function InputHandler:Hold(button)
	if self:IsHeld(button) then
		return
	end
	
	self:TriggerInput({
		InputType = button,
		InputState = Enum.UserInputState.Begin,
	})
end

function InputHandler:Release(button)
	if not self:IsHeld(button) then
		return
	end
	
	self:TriggerInput({
		InputType = button,
		InputState = Enum.UserInputState.End,
	})
end

return InputHandler
