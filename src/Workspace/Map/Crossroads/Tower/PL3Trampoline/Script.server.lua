local trampoline = script.Parent

for i, part in trampoline:GetChildren() do
	if not part:IsA("BasePart") then
		continue
	end
	
	if part.Name ~= "Bouncer" then
		continue
	end
	
	part.Touched:Connect(function(touchedPart)
		local model = touchedPart:FindFirstAncestorWhichIsA("Model")
		if not model then
			return
		end
		
		local humanoid = model:FindFirstChild("Humanoid")
		if not humanoid then
			return
		end
		
		
		local bv = Instance.new("BodyVelocity")
		bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		bv.Velocity = Vector3.new(0, 100, 0)
		bv.Parent = model.PrimaryPart
		task.delay(0.1, bv.Destroy, bv)
	end)
end