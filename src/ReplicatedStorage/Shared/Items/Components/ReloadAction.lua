local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")
local Timer = Framework.GetShared("Timer")

local AutoReloadDelay = 0.2

local ReloadAction = {}
ReloadAction.__index = ReloadAction
ReloadAction.ClassName = ReloadAction
setmetatable(ReloadAction, BaseClass)

function ReloadAction.new(item, action)
	local self = BaseClass.new()
	setmetatable(self, ReloadAction)
	
	self:InjectObject("Item", item)
	self:InjectObject("Action", item:GetActionManager():GetAction(action))
	
	local timers = {
		AutoDelay = Timer.new({
			Duration = function()
				return self.Action:GetConfig("AutoReloadDelay") or AutoReloadDelay
			end,
		}),
		
		First = Timer.new({
			Duration = function() 
				return self.Action:GetConfig("First") 
			end,
		}),
	}
	if self.Action:GetConfig("Consecutive") then
		self.IsConsecutive = true
		
		timers.Consecutive = Timer.new({
			Duration = function() 
				return self.Action:GetConfig("Consecutive")
			end
		})
		
		self.Action:AddEvent({
			Name = "ConsecutiveStart",
		})
	end
	
	self.Action:AddTimers(timers)
	self:AddConnections({
		StartReloadSequence = self.Action.Timers.AutoDelay:GetSignal("Ended"):Connect(function(completed, t, wasDestroyed)
			if not completed or wasDestroyed then
				return
			end
			
			self:Start()
		end),
		
		ItemUnequipped = self.Item:GetActionManager():GetActionStartedSignal("Unequip"):Connect(function()
			self:OnItemUnequip()
		end),
		
		ItemEquipped = self.Item:GetActionManager():GetActionEndedSignal("Equip"):Connect(function()
			self:OnItemEquip()
		end),
	})
	
	self.IsReloading = false
	self.AutoCleanup = true
	
	return self
end

function ReloadAction:ConnectAnimations()
	local item = self.Item
	local actionManager = item:GetActionManager()
	
	if self.IsConsecutive then
		item:AddConnections({
			PlayReloadBeginAnimation = actionManager:GetActionStartedSignal("Reload"):Connect(function()
				item.Animator:Play("ReloadBegin")
			end),

			PlayReloadConsecutiveAnimation = actionManager:GetActionEventSignal("Reload", "ConsecutiveStart"):Connect(function()
				item.Animator:Stop("ReloadBegin")
				item.Animator:Play("ReloadConsecutive")
			end),

			StopReloadBeginAnimation = actionManager:GetActionEndedSignal("Reload"):Connect(function(canceled)
				item.Animator:Stop("ReloadBegin", "ReloadConsecutive", "ReloadEnd")

				if not canceled then
					item.Animator:Play("ReloadEnd")
				end
			end),
		})
	else
		item:AddConnections({
			PlayReloadAnimation = actionManager:GetActionStartedSignal("Reload"):Connect(function()
				item.Animator:Play("Reload")
			end),

			StopReloadAnimation = actionManager:GetActionEndedSignal("Reload"):Connect(function(canceled)
				-- Only stop the animation if it's interrupted
				if canceled then
					item.Animator:Stop("Reload")
				end
			end),
		})
	end
end

function ReloadAction:CanReload()
	local reloadedValueName = self.Action:GetConfig("ReloadedValue")
	local reserveValueName = self.Action:GetConfig("ReserveValue")
	
	return self.Item:GetValue(reloadedValueName) < self.Item:GetValue(reloadedValueName, "Max") -- Is our clip not full?
		and self.Item:GetValue(reserveValueName) > 0 -- Do we have any reserve ammo?
		and self.Item:GetState("Active")
end

function ReloadAction:OnItemUnequip()
	self:Stop({Canceled = "Unequip"})
	self:CleanupConnections("ReloadedValueChanged", "ActionStarted")
end

function ReloadAction:OnItemEquip()
	local reloadedValueName = self.Action:GetConfig("ReloadedValue")
	self:BeginReloadSequence()
	
	self:AddConnections({
		ReloadedValueChanged = self.Item:GetValueManager():GetChangedSignal(reloadedValueName):Connect(function()
			-- Are we already reloading?
			if self.IsReloading then
				return
			end
			
			if not self:CanReload() then
				self:Stop({Canceled = true})
				return
			end
			
			self:BeginReloadSequence()
		end),
		
		ActionStarted = self.Item:GetActionManager():GetSignal("ActionEvent"):Connect(function(actionName, eventName)
			if eventName ~= "StartedSuccessfully" 
				or actionName == self.Action.ActionName or actionName == "Reload" then
				return
			end

			local ignoreList = self.Action:GetConfig("ActionIgnoreList")

			if not ignoreList then
				self:Stop({Canceled = true})
				return
			end
			-- Interrupt the reload
			if not ignoreList[actionName] or ignoreList[actionName] ~= eventName then
				self:Stop({Canceled = actionName})
			end
			
		end)
	})
end

function ReloadAction:BeginReloadSequence()
	local autoDelay = self.Action:GetTimer("AutoDelay")
	
	if not self:CanReload() or self.IsReloading or autoDelay.Active then
		return
	end

	autoDelay:Start()
end

function ReloadAction:Start()
	self.IsReloading = true
	
	if self.IsConsecutive then
		self:ReloadConsecutively()
	else
		self:ReloadSingly()
	end
end

function ReloadAction:ReloadSingly()
	local first = self.Action.Timers.First
	self:AddConnections({
		FirstStarted = self.Action:ConnectTo("StartedSuccessfully", function()
			first:Start()
		end),
		
		FirstCompleted = first:ConnectTo("Ended", function(completed, t, wasDestroyed)
			if not completed or wasDestroyed then
				return
			end
			
			self:AddToValuesSingly()
		end),
	})
	
	self.Action:StartEvent("Started")
end

function ReloadAction:AddToValuesSingly()
	local reloadedValueName = self.Action:GetConfig("ReloadedValue")
	local reserveValueName = self.Action:GetConfig("ReserveValue")
	
	local currentReserve = self.Item:GetValue(reserveValueName)

	self.Item:SetValues({
		[reserveValueName] = currentReserve - 
			math.min( self.Item:GetValue(reloadedValueName, "Max") - self.Item:GetValue(reloadedValueName), 
				currentReserve ),
		
		[reloadedValueName] = math.min( self.Item:GetValue(reloadedValueName, "Max"), self.Item:GetValue(reloadedValueName) + currentReserve ),
	}, {reserveValueName, reloadedValueName})
	
	self:Stop()
end

function ReloadAction:ReloadConsecutively()
	local first = self.Action:GetTimer("First")
	local consecutive = self.Action:GetTimer("Consecutive")
	
	-- Is any of this CanReload madness necessary???
	self:AddConnections({
		FirstStarted = self.Action:ConnectTo("StartedSuccessfully", function()
			first:Start()
		end),

		FirstCompleted = first:ConnectTo("Ended", function(completed, t, wasDestroyed)
			if wasDestroyed then
				return
			end
			
			if not completed or not self:CanReload() then
				self:Stop()
				return
			end

			consecutive:Start()
			self.Action:StartEvent("ConsecutiveStart")
		end),
		
		ConsecutiveEnd = consecutive:ConnectTo("Ended", function(completed, t, wasDestroyed)
			if wasDestroyed then
				return
			end
			
			if not completed or not self:CanReload() then
				self:Stop()
				return
			end
			
			self:AddToValuesConsecutively()
			
			if not self:CanReload() then
				self:Stop()
				return
			end
			
			consecutive:Start()
			self.Action:StartEvent("ConsecutiveStart")
		end)
	})

	self.Action:StartEvent("Started")
end

function ReloadAction:AddToValuesConsecutively()
	local reloadedValueName = self.Action:GetConfig("ReloadedValue")
	local reserveValueName = self.Action:GetConfig("ReserveValue")
	local reloadAmount = self.Action:GetConfig("ReloadAmount") or 1

	self.Item:SetValues({
		
		[reserveValueName] = self.Item:GetValue(reserveValueName) - reloadAmount,
		[reloadedValueName] = self.Item:GetValue(reloadedValueName) + reloadAmount,
		
	}, {reserveValueName, reloadedValueName})
end

function ReloadAction:ResetTimers()
	self.Action:GetTimer("AutoDelay"):Reset()
	self.Action:GetTimer("First"):Reset()
	
	local consecutive = self.Action:GetTimer("Consecutive")
	if consecutive then
		consecutive:Reset()
	end
end

function ReloadAction:Stop(args)
	self.IsReloading = false

	self:ResetTimers()
	self.Action:StartEvent("Ended", args)
end

function ReloadAction:Destroy()
	self:CleanupAllConnections()
	BaseClass.Destroy(self)
end

return ReloadAction
