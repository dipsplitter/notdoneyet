local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local Signal = Framework.GetShared("Signal")
local InputHandler = Framework.GetShared("InputHandler")

local UserInputService = game:GetService("UserInputService")

local lastMousePosition = Vector3.zero

local function IsMouseInput(inputObject)
	local inputType = inputObject.UserInputType
	return inputType == Enum.UserInputType.MouseButton1 
		or inputType == Enum.UserInputType.MouseButton2 
		or inputType == Enum.UserInputType.MouseButton3
end

local InputService = {
	InputHandler = InputHandler.new(),
	MouseDelta = lastMousePosition,
}

local mainHandler = InputService.InputHandler

function InputService.GetContext(contextName)
	return mainHandler:GetContext(contextName)
end

function InputService.CreateContext(contextParams)
	mainHandler:CreateContext(contextParams)
end

function InputService.DestroyContext(contextName)
	mainHandler:DestroyContext(contextName)
end

UserInputService.InputBegan:Connect(function(inputObject, gpe)
	if gpe then
		return
	end

	local inputType = inputObject.UserInputType

	if IsMouseInput(inputObject) then

		mainHandler:Hold(inputType)

	elseif inputType == Enum.UserInputType.Keyboard then

		mainHandler:Hold(inputObject.KeyCode)

	else

		local args = {
			InputState = inputObject.UserInputState,
			InputType = inputObject.UserInputType,
			Position = inputObject.Position,
			KeyCode = inputObject.KeyCode,
			Delta = inputObject.Delta,
		}

		mainHandler:TriggerInput(args)

	end
end)

UserInputService.InputChanged:Connect(function(inputObject, gpe)
	if gpe then
		return
	end
	
	local inputType = inputObject.UserInputType
	if inputType ~= Enum.UserInputType.MouseMovement then
		return
	end
	
	local isLocked = UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter
	local currentPosition = UserInputService:GetMouseLocation()
	currentPosition = Vector3.new(currentPosition.X, currentPosition.Y, 0)
	
	local mouseDirection
	if isLocked then
		mouseDirection = inputObject.Delta
	else
		mouseDirection = currentPosition - lastMousePosition
	end
	lastMousePosition = currentPosition
	
	InputService.MouseDelta = mouseDirection.Unit
end)

UserInputService.InputEnded:Connect(function(inputObject, gpe)
	if gpe then
		return
	end

	local inputType = inputObject.UserInputType

	if IsMouseInput(inputObject) then

		mainHandler:Release(inputType)

	elseif inputType == Enum.UserInputType.Keyboard then

		mainHandler:Release(inputObject.KeyCode)

	else

		local args = {
			InputState = inputObject.UserInputState,
			InputType = inputObject.UserInputType,
			Position = inputObject.Position,
			KeyCode = inputObject.KeyCode,
			Delta = inputObject.Delta,
		}

		mainHandler:TriggerInput(args)

	end
end)

return InputService
