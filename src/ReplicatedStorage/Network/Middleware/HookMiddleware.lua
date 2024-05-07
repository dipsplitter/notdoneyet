local MiddlewareFolder = script.Parent
local EventMiddleware = require(MiddlewareFolder.EventMiddleware)

return function(networkEvent, middlewareName)
	local middlewareTable = require(MiddlewareFolder[middlewareName])
	
	if not networkEvent.Middleware then
		networkEvent.Middleware = EventMiddleware.new()
	end

	local inbound = middlewareTable.Inbound
	if inbound then
		for name, callback in inbound do
			networkEvent.Middleware:AddInbound(name, callback)
		end
	end

	local outbound = middlewareTable.Outbound
	if outbound then
		for name, callback in outbound do
			networkEvent.Middleware:AddOutbound(name, callback)
		end
	end
end