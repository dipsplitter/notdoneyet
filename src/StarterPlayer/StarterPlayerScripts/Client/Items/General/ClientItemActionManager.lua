local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local ItemActionManager = Framework.GetShared("ItemActionManager")

local NETWORK = Framework.Network()
local ItemActionEvent = NETWORK.Event("ItemAction")

local ClientItemActionManager = {}
ClientItemActionManager.__index = ClientItemActionManager
ClientItemActionManager.ClassName = "ClientItemActionManager"
setmetatable(ClientItemActionManager, ItemActionManager)

function ClientItemActionManager.new(params)
	local self = ItemActionManager.new(params)
	setmetatable(self, ClientItemActionManager)
	
	-- The item's id
	self.EntityHandle = params.EntityHandle
	self.IsNetworked = true
	
	self:AutoReplicateActionEvents()
	
	return self
end

function ClientItemActionManager:StartActionEventFromServerRequest(args)
	local action = self:GetAction(args.ActionName)
	if not action then
		return
	end
	
	args.ServerInitiated = true
	args.EventName = args.EventName or "Started"
	
	action:StartEvent(args.EventName, args)
end

function ClientItemActionManager:FireServer(argsTable)
	local netArgs = {
		ActionManager = self,
		EventName = argsTable.EventName,
		ActionName = argsTable.ActionName,
		Args = argsTable.Args
	}
	
	ItemActionEvent:Fire(netArgs)
end

function ClientItemActionManager:StartActionEventWithReplication(args)
	if args.ServerInitiated then
		return
	end
	
	local action = self:GetAction(args.ActionName)
	if not action then
		return
	end
	
	args.Replicate = nil
	args.EventName = args.EventName or "Started"
	action:StartEvent(args.EventName, args)
	
	self:FireServer(args)
end

function ClientItemActionManager:AutoReplicateActionEvents()
	self:AddConnections({
		AutomaticallyReplicateActionEvent = self.Signals.ActionEvent:Connect(function(actionName, eventName, args)
			if not args then
				return
			end

			if not args.Replicate then
				return
			end
			
			args.Replicate = nil
			
			-- Add action and event IDs to args table for the networking
			args.ActionName = actionName
			args.EventName = eventName
			self:FireServer(args)
		end)
	})
end

return ClientItemActionManager
