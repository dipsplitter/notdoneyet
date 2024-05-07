local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local MeleeWeapon = Framework.GetShared("MeleeWeapon")
local ActionManagerConnector = Framework.GetShared("ActionManagerConnector")

local BaseMelee = Framework.GetShared("ClassicSword")

local Fists = {}

function Fists.new(params)
	params.Id = params.Id or "Fists"

	local melee = BaseMelee.new(params)
	
	return melee
end

return Fists
