--[[
	Client: A wrapper for ContextActionService
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")

local RunService = game:GetService("RunService")
local IsClient = RunService:IsClient()
local IsServer = RunService:IsServer()

local InputContext = {}
InputContext.__index = InputContext
InputContext.ClassName = "InputContext"
setmetatable(InputContext, BaseClass)

function InputContext.new(params)
	local self = BaseClass.new()
	setmetatable(self, InputContext)
	
	self.Keybinds = params.Keybinds
	self.ValidInputStates = params.ValidInputStates
	self.ContextName = params.ContextName
	
	self:InjectObject("InputHandler", params.InputHandler)
	
	if not params.BindLater then
		self:Bind()
	end
	
	self:AddSignals("Triggered")
	
	return self
end

function InputContext:Bind()
	if not self.InputHandler then
		return
	end
	
	self:AddConnections({
		HandleInput = self.InputHandler:GetSignal("InputOccurred"):Connect(function(inputInfo)
			local inputState = inputInfo.InputState
			local inputType = inputInfo.InputType
			
			if self.ValidInputStates then
				if not self.ValidInputStates[inputState] then
					return
				end
			end
			
			if not self:IsValidKeybind(inputType) then
				return
			end
			
			self:FireSignal("Triggered", inputInfo, self.ValidInputStates[inputState])
		end)
	})
end

function InputContext:SetInputHandler(newInputHandler)
	self:CleanupConnection("HandleInput")
	self:InjectObject("InputHandler", newInputHandler) 

	if self.InputHandler then
		self:Bind()
	end
end

function InputContext:UnpackKeybinds()
	if type(self.Keybinds) == "table" then
		return table.unpack(self.Keybinds)
	end

	return self.Keybinds
end

function InputContext:IsValidKeybind(keyEnum)
	if type(self.Keybinds) == "table" then
		return table.find(self.Keybinds, keyEnum)
	end
	
	return self.Keybinds == keyEnum
end

function InputContext:SetKeybinds(newKeybinds)
	self.Keybinds = newKeybinds
end

function InputContext:Unbind()
	self:CleanupConnection("HandleInput")
end

function InputContext:Destroy()
	if self.InputHandler then
		self.InputHandler:RemoveContext(self.ContextName)
	end
	
	self:BaseDestroy()
end

return InputContext
