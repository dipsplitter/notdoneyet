local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local ResourceUtilities = Framework.GetShared("ResourceUtilities")

local ParseAnimationProperties = require(script.ParseAnimationProperties)

local TweenService = game:GetService("TweenService")

local specialKeys = {
	StopEvents = true,
	StartEvents = true,
	Duration = true,
}

local UiAnimator = {}
UiAnimator.__index = UiAnimator

function UiAnimator.new(ui, resource)
	local self = {}
	setmetatable(self, UiAnimator)
	
	self.Ui = ui
	self.Resource = ResourceUtilities.MergeWithParentResource(resource)
	self.Animations = resource.Animations
	
	self.Styles = if self.Animations then self.Animations.Styles else {}
	
	-- Caches
	self.TweenInfos = {}
	self.CachedGoals = {}

	-- Ui components
	self.Components = {}
	self.InitialProperties = {}
	
	self.ActiveTweenObjects = {}
	self.Threads = {}
	
	self:OnResourceChange()
	
	return self
end

function UiAnimator:OnResourceChange()
	-- I don't know. I'm going insane writing this...
	table.clear(self.TweenInfos)
	table.clear(self.CachedGoals)
	table.clear(self.InitialProperties)
	
	for i, descendant in self.Ui:GetDescendants() do
		local descendantFieldName = descendant.Name
		if self.Resource[descendantFieldName] then
			self.Components[descendantFieldName] = descendant
		end
	end

	self.Components.Main = self.Ui
end

function UiAnimator:CancelAllThreads()
	for animationName, threads in self.Threads do
		for threadName, thread in threads do
			task.cancel(thread)
			threads[threadName] = nil
		end
	end
end

function UiAnimator:CancelThreads(animationName)
	local threadsTable = self.Threads[animationName]
	if not threadsTable then
		return
	end
	
	for threadName, thread in threadsTable do
		task.cancel(thread)
		threadsTable[threadName] = nil
	end
end

function UiAnimator:GetTweenInfo(animationName, componentName)
	local data = self.Animations[animationName]
	local styleName = data[componentName].Style
	
	if typeof(styleName) == "TweenInfo" then
		return styleName
	end
	
	local key = `{animationName}{componentName}`
	local existingTweenInfo = self.TweenInfos[key]
	if existingTweenInfo then
		return existingTweenInfo
	end
	
	local data = self.Animations[animationName]
	local tweenInfo = self.Styles[styleName]
	
	local newTweenInfo = TweenInfo.new(
		data.Duration or tweenInfo.Time,
		tweenInfo.EasingStyle,
		tweenInfo.EasingDirection,
		tweenInfo.RepeatCount,
		tweenInfo.Reverses,
		data.DelayTime or tweenInfo.DelayTime
	) 
	
	self.TweenInfos[key] = newTweenInfo
	
	return newTweenInfo
end

function UiAnimator:RunEvents(animationName)
	local data = self.Animations[animationName]
	local stopEvents = data.StopEvents or {}
	local startEvents = data.StartEvents or {}
	
	local threadsTable = self.Threads[animationName]
	if not threadsTable then
		self.Threads[animationName] = {}
		threadsTable = self.Threads[animationName]
	end
	
	-- Stop events
	for animationName, delayTime in stopEvents do
		if delayTime == 0 then
			self:Stop(animationName)
		else
			threadsTable[`Stop{animationName}`] = task.delay(delayTime, function()
				self:Stop(animationName)
			end)
		end
	end

	-- Start events
	for animationName, delayTime in startEvents do
		if delayTime == 0 then
			self:Animate(animationName)
		else
			threadsTable[`Start{animationName}`] = task.delay(delayTime, function()
				self:Animate(animationName)
			end)
		end
	end
end

function UiAnimator:ClearActiveTweens(animationName)
	local activeTweens = self.ActiveTweenObjects[animationName]
	if not activeTweens then
		self.ActiveTweenObjects[animationName] = {}
		activeTweens = self.ActiveTweenObjects[animationName]
	end
	
	for componentName, tweenObject in activeTweens do
		if type(tweenObject) == "table" then
			for instance, tween in tweenObject do
				tween:Cancel()
				tween:Destroy()
			end
		else
			tweenObject:Cancel()
			tweenObject:Destroy()
		end
	end
	
	table.clear(self.ActiveTweenObjects[animationName])
end

function UiAnimator:Animate(animationName)
	local data = self.Animations[animationName]
	
	self:Stop(animationName)
	self:RunEvents(animationName)

	local activeTweens = self.ActiveTweenObjects[animationName]
	
	for componentName, info in data do
		if specialKeys[componentName] then
			continue
		end
		
		local key = `{animationName}{componentName}`
		
		local tweenInfo = self:GetTweenInfo(animationName, componentName)
		local component = self.Components[componentName]
		
		if not component then
			continue
		end
		
		activeTweens[componentName] = {}
		
		-- Cache goal properties
		local goalsDict = self.CachedGoals[key]
		if not goalsDict then
			goalsDict = ParseAnimationProperties.ParseGoals(component, info.Goals, self.Resource)
			self.CachedGoals[key] = goalsDict
		end
		
		-- Cache initial properties
		local initialsDict = self.InitialProperties[key] 
		if not initialsDict then 
			
			if info.Initials then
				self.InitialProperties[key] = ParseAnimationProperties.ParseGoals(component, info.Initials, self.Resource)
			else
				self.InitialProperties[key] = ParseAnimationProperties.ParseInitials(component, goalsDict)
			end
			
		end
		
		-- One animation can generate multiple tweens because of damned TextStroke needing to change UIStroke properties
		for instance, goals in goalsDict do
			local tween = TweenService:Create(instance, tweenInfo, goals)
			activeTweens[componentName][instance] = tween
			
			tween:Play()
			tween.Completed:Once(function()
				activeTweens[componentName][instance] = nil
			end)
		end
		
	end
end

function UiAnimator:IsAnimationActive(animationName)
	local tweenTable = self.ActiveTweenObjects[animationName]
	return tweenTable and next(tweenTable)
end

function UiAnimator:Stop(animationName)
	local data = self.Animations[animationName]
	self:ClearActiveTweens(animationName)
	self:CancelThreads(animationName)
	
	for componentName in data do
		local initials = self.InitialProperties[`{animationName}{componentName}`]
		if not initials then
			continue
		end
		
		for instance, props in initials do
			
			for propertyName, initialValue in props do
				instance[propertyName] = initialValue
			end
			
		end
	end
end

function UiAnimator:Destroy()
	self:CancelAllThreads()
	
	if self.Animations then
		for animationName in self.Animations do
			self:ClearActiveTweens(animationName)
		end
	end

	setmetatable(self, nil)
	table.clear(self)
	table.freeze(self)
end

return UiAnimator
