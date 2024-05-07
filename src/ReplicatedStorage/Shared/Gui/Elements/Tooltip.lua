local UserInputService = game:GetService("UserInputService")

local Tooltip = {}
Tooltip.__index = Tooltip

function Tooltip.new(params)
	local self = {
		Parent = params.Parent,
		Trigger = params.Trigger,
		Ui = params.Ui,
	}
	setmetatable(self, Tooltip)
	
	self.FollowsMouse = params.FollowsMouse
	self.MouseOffset = params.MouseOffset or Vector2.zero
	
	self.EnableTask = nil
	self.MoveConnection = self.Trigger.MouseMoved:Connect(function()
		self:Enable()
	end)
	
	self.LeaveConnection = self.Trigger.MouseLeave:Connect(function()
		self:Disable()
	end)
	
	self.VisibleConnection = self.Trigger:GetPropertyChangedSignal("Visible"):Connect(function()
		if self.Trigger.Visible == false then
			self:Disable()
		end
	end)
	
	self.AutoDestroyConnection = self.Trigger.Destroying:Connect(function()
		self:Destroy()
	end)

	return self
end

function Tooltip:Enable()
	local mousePosition = UserInputService:GetMouseLocation()
	local position = UDim2.new(0, mousePosition.X, 0, mousePosition.Y) + UDim2.new(0, self.MouseOffset.X, 0, self.MouseOffset.Y)
	
	self.Ui.Visible = true
	self.Ui.Position = position
	
	if not self.Ui.Parent then
		self.Ui.Parent = self.Parent
	end
end

function Tooltip:Disable()
	self.Ui.Visible = false
	self.Ui.Parent = nil
end

function Tooltip:Destroy()
	self.MoveConnection:Disconnect()
	self.LeaveConnection:Disconnect()
	self.VisibleConnection:Disconnect()
	self.AutoDestroyConnection:Disconnect()
	
	self.Ui:Destroy()
	
	if self.EnableTask then
		task.cancel(self.EnableTask)
	end
	
	setmetatable(self, nil)
	table.clear(self)
	table.freeze(self)
end

return Tooltip
