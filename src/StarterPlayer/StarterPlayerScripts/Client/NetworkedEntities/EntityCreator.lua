local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local ProjectileSchema = Framework.GetShared("ProjectileSchema")

local entityTypes = {
	Projectile = function(className, ...)
		local module = ProjectileSchema.GetScript(className)
		
		return module.Create(...)
	end,
	
	Character = function(className)
		return
	end,
}

return function(params)
	local entityType = params.EntityType
	local className = params.ClassName
	
	-- We passed a string like "Projectile.Fireball" and we were too lazy to split it before
	if not entityType and not className then
		entityType, className = table.unpack(string.split(params.FullName, "."))
	end
	
	return entityTypes[entityType](className, params)
end
