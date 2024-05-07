-- NOT DONE

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")
local CircularBuffer = Framework.GetShared("CircularBuffer")
local TableUtilities = Framework.GetShared("TableUtilities")

local RunService = game:GetService("RunService")

local UpdateTime = 0.025

local InputBuffer = {}
InputBuffer.__index = InputBuffer
InputBuffer.ClassName = "InputBuffer"
setmetatable(InputBuffer, BaseClass)

function InputBuffer.new(inputHandler, size)
	local self = BaseClass.new()
	setmetatable(self, InputBuffer)
	
	self.InputHandler = inputHandler
	self.Buffer = CircularBuffer.new(size)
	
	self.CurrentInputs = {}
	self.NextHeartbeatInputs = {}
	
	self:AddConnections({
		AddInput = self.InputHandler:GetSignal("InputOccurred"):Connect(function(inputInfo)
			local inputType = inputInfo.InputType
			local inputState = inputInfo.InputState
			
			self.CurrentInputs[inputType] = inputState or Enum.UserInputState.Change
		end),
		
		Heartbeat = RunService.Heartbeat:Connect(function(dt)
			local recentInputsCopy = TableUtilities.Copy(self.CurrentInputs)
			self.CurrentInputs = {}
			
			self.Buffer:Push(recentInputsCopy)
		end)
	})

	return self
end

return InputBuffer
