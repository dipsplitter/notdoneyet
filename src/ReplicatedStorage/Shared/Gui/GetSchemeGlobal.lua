local Gui = script.Parent
local SchemesFolder = Gui.Schemes

local schemes = {
	Fonts = require(SchemesFolder.Fonts),
	Colors = require(SchemesFolder.Colors),
}

local GetSchemeGlobal = {}

function GetSchemeGlobal.Typed(resource, schemeName, alias)
	-- Was declared uniquely in the resource
	if type(alias) ~= "string" then
		return alias
	end

	-- Check in resource local scheme
	local resourceGlobal = resource[schemeName]
	if resourceGlobal then
		alias = resourceGlobal[alias]
	end

	-- Alias for a scheme global
	local schemeEntry = schemes[schemeName][alias]
	if schemeEntry then
		alias = schemeEntry
	end

	if type(alias) ~= "string" then
		return alias
	end
end

function GetSchemeGlobal.Untyped(resource, alias)
	for schemeName in schemes do
		local result = GetSchemeGlobal.Typed(resource, schemeName, alias)

		if result then
			return result
		end
	end
end

return GetSchemeGlobal
