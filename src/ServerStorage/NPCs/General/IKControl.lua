local IKControl = {}
IKControl.__index = IKControl
IKControl.ClassName = "IKControl"

function IKControl.new(params)
	local self = setmetatable({}, IKControl)
	
	self.Model = params.Model
	
	self.IK = Instance.new("IKControl")
	self.IK.EndEffector = self.Model:FindFirstChild(params.EndEffector)
	self.IK.ChainRoot = self.Model:FindFirstChild(params.ChainRoot) or self.IK.EndEffector
	self.IK.Weight = params.Weight or 0.9
	self.IK.Type = params.Type or Enum.IKControlType.LookAt
	self.IK.Enabled = false
	
	self.IK.Parent = self.Model:FindFirstChildOfClass("Humanoid")
	
	return self
end

function IKControl:LookAt(target)
	self.IK.Type = Enum.IKControlType.LookAt
	
	if target:IsA("Model") then
		target = target.PrimaryPart
	end
	
	self.IK.Target = target
	self.IK.Enabled = true
end

function IKControl:Reset()
	self.IK.Enabled = false
	self.IK.Target = nil
end

function IKControl:Destroy()
	self.IK:Destroy()
	self.IK = nil
	
	self.Model = nil
end

return IKControl
