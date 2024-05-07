local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local InstanceCreator = Framework.GetShared("InstanceCreator")

local PhysicsService = game:GetService("PhysicsService")

local PhysicsUtilities = {}

function PhysicsUtilities.ReflectVector(vector, normal)
	return vector - ( (normal * normal:Dot(vector)) * 2 )
end

function PhysicsUtilities.ClipVector(vector, normal)
	return vector - (normal * normal:Dot(vector))
end

function PhysicsUtilities.AABBCollision(posA, bboxA, posB, bboxB)
	local delta = posA - posB
	local mahattanDistance = Vector3.new(math.abs(delta.X), math.abs(delta.Y), math.abs(delta.Z)) - bboxA / 2 - bboxB / 2
	
	return mahattanDistance.X < 0 and mahattanDistance.Y < 0 and mahattanDistance.Z < 0
end

function PhysicsUtilities.IsValidCollision(part, collidedPart)
	local partCollisionGroup = part.CollisionGroup
	local collidedCollisionGroup = collidedPart.CollisionGroup
	
	return PhysicsService:CollisionGroupsAreCollidable(partCollisionGroup, collidedCollisionGroup)
end

function PhysicsUtilities.CreateBoundingBoxPart(model, boundShape)
	local extentsSize = model:GetExtentsSize()
	
	local bb = InstanceCreator.Create("Part", {
		Name = "BoundingBox",
		Size = extentsSize,
		Massless = true,
		CFrame = model:GetPivot(),
		Shape = boundShape or Enum.PartType.Block,
		Transparency = 1,
		Parent = model
	})
	
	local bbWeld = InstanceCreator.Create("WeldConstraint", {
		Name = "BoundingBoxWeld",
		Part0 = bb,
		Part1 = model.PrimaryPart,
		Parent = bb
	})
	
	return bb 
end

return PhysicsUtilities
