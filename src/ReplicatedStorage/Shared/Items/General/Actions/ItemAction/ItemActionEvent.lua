local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")

local ItemActionEvent = {}
ItemActionEvent.__index = ItemActionEvent
ItemActionEvent.ClassName = "ItemActionEvent"
setmetatable(ItemActionEvent, BaseClass)

function ItemActionEvent.new(params)
	local self = BaseClass.new()
	setmetatable(self, ItemActionEvent)
	
	self.EventName = params.Name
	
	self.SuccessEvaluator = params.SuccessEvaluator
	self.AutoFireSuccess = Framework.DefaultTrue(params.AutoFireSuccess)
	
	self.InitialEvaluator = params.InitialEvaluator
	
	--[[
		Normal: signal to fire when event starts before any success evaluation is performed 
		(will not fire if initial evaluator returns false)
		
		Success: signal to fire when success evaluator returns true
		
		General: signal to fire when any other signal has been fired
	]]
	self.EventSignals = params.Signals
	
	--[[
		Event listeners are signals that start the event upon being fired
	]]
	self.EventListeners = {} 
	self:ConnectEventListeners(params.EventListeners or {})
	
	self:ConnectSuccessEvaluator()
	
	--[[
		FailedInitial: if initial evaluator returns false
		Initial: initial returned true
		Failed: if success evaluator returns false
		Success: after success signal is fired
	]]
	self.Callbacks = params.Callbacks or {}
	
	return self	
end

function ItemActionEvent:Callback(name, ...)
	if self.Callbacks[name] then
		self.Callbacks[name](...)
	end
end

function ItemActionEvent:ConnectEventListeners(dict)
	for name, signal in pairs(dict) do
		self:AddConnections({
			[name] = signal:Connect(function(args)
				self:Start(args)
			end)
		})
	end
end

function ItemActionEvent:Start(args)
	if self.InitialEvaluator then
		if not self.InitialEvaluator(args) then
			self:Callback("FailedInitial")
			return
		end
	end
	
	local function callback(successArgs)
		self.EventSignals.Success:Fire(successArgs)
		self.EventSignals.General:Fire(self.EventName .. "Successfully", successArgs)
		
		self:Callback("Success")
	end

	self.EventSignals.Normal:Fire(args, callback)
	self.EventSignals.General:Fire(self.EventName, args)
	
	self:Callback("Initial")
end

function ItemActionEvent:SetSuccessEvaluator(eval)
	self.SuccessEvaluator = eval
end

function ItemActionEvent:SetInitialEvaluator(eval)
	self.InitialEvaluator = eval
end

function ItemActionEvent:ConnectSuccessEvaluator()
	self:AddConnections({
		["SuccessEvaluatorConnection"] = self.EventSignals.Normal:Connect(function(args, callback)
			if self.SuccessEvaluator then
				local result = self.SuccessEvaluator(args)

				if result then
					-- Fire success signal 
					callback(args)
				else
					self:Callback("Failed")
				end
			else
				
				-- Fire success signal if we don't care about checking the event's context
				if self.AutoFireSuccess then
					callback(args)
				end
				
			end
			
		end)
	})
end

function ItemActionEvent:Destroy()
	self.EventSignals = nil
	self.SuccessEvaluator = nil
	self.InitialEvaluator = nil
	
	self:BaseDestroy()
end

return ItemActionEvent
