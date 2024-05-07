local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local Signal = Framework.GetShared("Signal")
local UiViewHandler = Framework.GetShared("UiViewHandler")

local UserInputService = game:GetService("UserInputService")

local BaseMenu = {}
BaseMenu.__index = BaseMenu

function BaseMenu.new(screenGui, keybind)
	local self = {
		Ui = screenGui,
		Enabled = Signal.new(),
		ToggleConnection = nil,
	}
	setmetatable(self, BaseMenu)
	
	self:SetToggleKeybind(keybind)
	
	return self
end

function BaseMenu:SetToggleKeybind(keybind)
	self.Keybind = keybind
	
	if self.ToggleConnection then
		self.ToggleConnection:Disconnect()
		self.ToggleConnection = nil
	end
	
	if keybind then
		self.ToggleConnection = UserInputService.InputBegan:Connect(function(inputObject, processed)
			if processed then
				return
			end
			
			if inputObject.KeyCode ~= keybind then
				return
			end
			
			if self.Ui.Enabled then
				self:SetEnabled(false)
			else
				self:SetEnabled(true)
			end
		end)
	end
end

function BaseMenu:SetEnabled(state)
	-- Disabling, so remove from queue and set the next one as enabled
	if not state then
		UiViewHandler.Disable(self.Ui.Name)
	else
		UiViewHandler.Enable(self.Ui.Name)
	end
	
	self.Ui.Enabled = state
	
	self.Enabled:Fire(state)
end

return BaseMenu
