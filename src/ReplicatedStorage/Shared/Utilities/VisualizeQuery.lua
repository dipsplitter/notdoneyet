local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local InstanceCreator = Framework.GetShared("InstanceCreator")
local ColorUtilities = Framework.GetShared("ColorUtilities")

local Debris = game:GetService("Debris")

local OriginVisualizer = script.Origin
local BlockcastIndicator = script.BlockcastIndicator
local SpherecastIndicator = script.SpherecastIndicator

local PartFadeTime = 5
local RaycastWidth = 0.2
local AreaQueriedTransparency = 0.75

local ColorsConfig = {
	RaycastLine = Color3.fromRGB(255, 11, 11),
}

local VisualizeQuery = {}

function VisualizeQuery.VisualizeRaycast(origin, direction, range, raycastParams)
	local goal = origin + direction
	
	local clone = InstanceCreator.Clone(OriginVisualizer, {
		CFrame = CFrame.lookAt(origin, goal)
	})
	local line = InstanceCreator.Clone(BlockcastIndicator, {
		Color3 = ColorsConfig.RaycastLine,
		CFrame = CFrame.new(0, 0, -range / 2),
		Size = Vector3.new(RaycastWidth, RaycastWidth, range),
		Adornee = clone,
		Parent = clone,
		Transparency = AreaQueriedTransparency,
	})
	
	Debris:AddItem(clone, PartFadeTime)
	
	local result = workspace:Raycast(origin, direction * range, raycastParams)
	if result then
		clone.Intersection.Visible = true
		clone.Intersection.CFrame = CFrame.new(result.Position):ToObjectSpace(clone.CFrame):Inverse()
	end
end

function VisualizeQuery.VisualizeBlockcast(cframe, size, direction, raycastParams)
	local goal = cframe.Position + direction

	local clone = InstanceCreator.Clone(OriginVisualizer, {
		CFrame = CFrame.lookAt(cframe.Position, goal)
	})
	
	local box = InstanceCreator.Clone(BlockcastIndicator, {
		CFrame = CFrame.new(0, 0, -direction.Magnitude / 2),
		Size = Vector3.new(size.X, size.Y, -direction.Magnitude),
		Transparency = AreaQueriedTransparency,
		Adornee = clone,
		Parent = clone,
	})
	
	Debris:AddItem(clone, PartFadeTime)
	
	local result = workspace:Blockcast(cframe, size, direction, raycastParams)

	if result then
		local finalPos = cframe.Position + (direction.Unit * result.Distance)
		
		local hitBox = InstanceCreator.Clone(BlockcastIndicator, {
			Color3 = ColorUtilities.Invert(BlockcastIndicator.Color3),
			Size = size,
			CFrame = CFrame.new(0, 0, -result.Distance),
			Adornee = clone,
			Parent = clone,
			ZIndex = 4,
		})
		
		clone.Intersection.Visible = true
		clone.Intersection.CFrame = CFrame.new(result.Position):ToObjectSpace(clone.CFrame):Inverse()
	end
end

function VisualizeQuery.VisualizeBoxQuery(cframe, size)
	
	local clone = InstanceCreator.Clone(OriginVisualizer, {
		CFrame = cframe
	})
	
	local box = InstanceCreator.Clone(BlockcastIndicator, {
		Size = size,
		Transparency = AreaQueriedTransparency,
		Adornee = clone,
		Parent = clone,
	})
	
	Debris:AddItem(clone, PartFadeTime)
	
end

function VisualizeQuery.VisualizeSphereQuery()
	
end

function VisualizeQuery.VisualizePartQuery()
	
end

return VisualizeQuery
