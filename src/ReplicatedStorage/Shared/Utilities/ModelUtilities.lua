local ModelUtilities = {}

function ModelUtilities.Anchor(model, state)
	for i, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = state
		end
	end
end

function ModelUtilities.SetTransparency(model, transparency)
	for i, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") and not part:GetAttribute("LockTransparency") then
			part.Transparency = transparency
		end
	end
end

function ModelUtilities.SetInteractive(model, state)
	for i, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = state
			part.CanTouch = state
			part.CanQuery = state
		end
	end
end

function ModelUtilities.SetCollidable(model, state)
	for i, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = state
		end
	end
end


function ModelUtilities.Lock(model, state)
	ModelUtilities.Anchor(model, state)
	ModelUtilities.SetInteractive(model, not state)
end

function ModelUtilities.LockCharacter(model, state)
	model.PrimaryPart.Anchored = state
	
	for i, part in model:GetChildren() do
		if not part:IsA("BasePart") or part.Name == "HumanoidRootPart" or part.Name == "BoundingBox" then
			continue
		end
		
		part.CanCollide = not state
		part.CanTouch = not state
		part.CanQuery = not state
		part.Transparency = if state then 1 else 0
	end
end

function ModelUtilities.SetCollisionGroup(model, name)
	for i, descendant in pairs(model:GetDescendants()) do
		if not descendant:IsA("BasePart") then
			continue
		end
		
		descendant.CollisionGroup = name
	end
end

function ModelUtilities.PivotTo(model, position)
	if typeof(position) == "Vector3" then
		position = CFrame.new(position)
	end

	model:PivotTo(position)
end

function ModelUtilities.SetServerOwned(model)
	for i, descendant in pairs(model:GetDescendants()) do
		if not descendant:IsA("BasePart") then
			continue
		end
		
		if descendant:CanSetNetworkOwnership() then
			descendant:SetNetworkOwner(nil)
		end
	end
end

function ModelUtilities.SetClientOwned(model, client)
	if model.PrimaryPart:CanSetNetworkOwnership() then
		model.PrimaryPart:SetNetworkOwner(client)
	end
end

function ModelUtilities.SetShared(model)
	if model.PrimaryPart:CanSetNetworkOwnership() then
		model.PrimaryPart:SetNetworkOwnershipAuto()
	end
end

return ModelUtilities
