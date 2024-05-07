local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local ReadBuffer = Framework.GetShared("ReadBuffer")
local BitFlagUtilities = Framework.GetShared("BitFlagUtilities")
local EnumService = Framework.GetShared("EnumService")

local IndicatorType_Damage = {
	FlagBits = 16,
	Flags = EnumService.GetEnum("Enum_DamageIndicatorFlags"),
}

function IndicatorType_Damage.Serialize(args, queue)
	local damageEvent = args.DamageEvent
	local damageResults = args.DamageResults
	
	local target = damageEvent.Target
	if not target then
		return
	end
	
	queue:writeu16(target.Id)
	queue:writeu8(args.IndicatorType)
	
	local flags = 0

	local flagsTable, bitFlags = damageEvent.DamageType.Flags, IndicatorType_Damage.Flags
	if next(flagsTable) then
		flags = BitFlagUtilities.Serialize(flagsTable, bitFlags)
	end
	
	-- First 2 bits: health damage and/or armor damage
	-- Write health and armor damage numbers
	local hasArmorDamage = next(damageResults.Armor) and damageResults.Armor.Total ~= 0
	local hasHealthDamage = next(damageResults.Health) and damageResults.Health.Total ~= 0
	
	if hasArmorDamage then
		flags = bit32.bor(flags, bitFlags.Armor)
	end
	
	if hasHealthDamage then
		flags = bit32.bor(flags, bitFlags.Health)
	end
	queue:writeu16(flags)
	
	if hasArmorDamage then
		queue:writef32(damageResults.Armor.Total)
	end

	if hasHealthDamage then
		queue:writef32(damageResults.Health.Total)
	end
end

function IndicatorType_Damage.Deserialize(stream, cursor, data)
	local readBuffer = ReadBuffer.new(stream, cursor)
	local flags = data.Flags
	
	local damageTable = {}
	local hasArmorDamage = flags.Armor
	local hasHealthDamage = flags.Health

	if (hasArmorDamage and hasHealthDamage) or not flags then
		
		damageTable.Armor = readBuffer:readf32()
		damageTable.Health = readBuffer:readf32()
		
	elseif hasArmorDamage then
		
		damageTable.Armor = readBuffer:readf32()
		
	elseif hasHealthDamage then
		
		damageTable.Health = readBuffer:readf32()
		
	end
	
	for key, number in damageTable do
		number = math.floor(number)
	end

	data.DamageTable = damageTable
	
	return readBuffer:GetBytesRead()
end

return IndicatorType_Damage
