local NPCKnownEntity = {}
NPCKnownEntity.__index = NPCKnownEntity
NPCKnownEntity.ClassName = "NPCKnownEntity"

function NPCKnownEntity.new(model, autoForgetTime)
	local self = setmetatable({
		IsVisible = false, -- Flagged by vision update
		
		Character = model,
		
		LastSeen = 0, -- Updates when the character is marked visible regardless of its prior state
		LastBecameVisible = 0, -- Updates when the character transitions from invisible to visible
		BecameKnown = os.clock(),
		
		LastKnownPosition = Vector3.zero,
		LastKnownVelocity = Vector3.zero,
		EstimatedPosition = Vector3.zero,
		
		LastKnownPositionSeen = false, -- Whether the NPC can raycast to the last known position
		LastKnownTimestamp = 0, -- Updates when we know their position (auditory or visual)
		
		AutoForgetTime = autoForgetTime or 10
		
	}, NPCKnownEntity)
	
	self:UpdatePosition()
	
	return self
end

function NPCKnownEntity:UpdatePosition()
	-- If this is our first update
	local lastKnown = if self.LastKnownTimestamp == 0 then self.BecameKnown else self.LastKnownTimestamp
	local primaryPart = self.Character.PrimaryPart
	
	self.LastKnownPosition = primaryPart.Position
	self.LastKnownVelocity = primaryPart.AssemblyLinearVelocity
	self.LastKnownTimestamp = os.clock()
	
	self.EstimatedPosition = self.LastKnownPosition + (self.LastKnownVelocity * (self.LastKnownTimestamp - lastKnown))
end

function NPCKnownEntity:MarkLastKnownPositionAsSeen()
	self.LastKnownPositionSeen = true
end

function NPCKnownEntity:WasEverVisible()
	return self.LastSeen > 0
end

function NPCKnownEntity:GetTimeSinceLastSeen()
	return os.clock() - self.LastSeen
end

function NPCKnownEntity:GetTimeSinceLastKnown()
	return os.clock() - self.LastKnownTimestamp
end

function NPCKnownEntity:GetTimeSinceBecameKnown()
	return os.clock() - self.BecameKnown
end

function NPCKnownEntity:UpdateVisibility(state)
	if state then
		if not self.IsVisible then
			self.LastBecameVisible = os.clock()
		end
		
		self.LastSeen = os.clock()
	end
	
	self.IsVisible = state
end

function NPCKnownEntity:WasRecentlyVisible()
	if self.IsVisible then
		return true
	end
	
	if self:WasEverVisible() and self:GetTimeSinceLastSeen() < 3 then
		return true
	end
	
	return false
end

function NPCKnownEntity:IsObsolete()
	return self:GetTimeSinceLastSeen() >= self.AutoForgetTime or not self.Character or not self.Character.Parent
end

function NPCKnownEntity:Destroy()
	self.Character = nil
	
	table.clear(self)
end

return NPCKnownEntity
