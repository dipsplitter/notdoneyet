local charactersList = {}

local DamageHistory = {}

function DamageHistory.RegisterCharacter(character)
	charactersList[character] = {}
end

function DamageHistory.LogDamage(target, attacker)
	if not charactersList[target] then
		DamageHistory.RegisterCharacter(target)
	end
	
	local list = charactersList[target]
	
	local currentTime = workspace:GetServerTimeNow()
	local entry = {
		CurrentTime = currentTime,
		Attacker = attacker,
	}
	
	-- Check the most recent damage event
	-- If it matches, update the time
	local mostRecentEntry = list[#list]
	if mostRecentEntry.Attacker == attacker then
		mostRecentEntry.CurrentTime = currentTime
	else
		table.insert(list, entry)
	end
end

return DamageHistory
