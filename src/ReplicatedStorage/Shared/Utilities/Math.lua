local TAU = 2 * math.pi

local Math = {}

function Math.ClearFloatingPointError(number, decimalPlaces)
	local str = tostring(number)
	decimalPlaces = math.max(decimalPlaces, 0)
	
	local formatted = string.format(`%.{decimalPlaces}f`, number)
	formatted = formatted:gsub("%.?0+$", "") or 0
	
	return tonumber(formatted)
end

--[[
	Rounds to the specified number of decimal places
	0: nearest integer (default)
	> 0: tenths, hundredths, etc.
	< 0: tens, hundreds, etc.
]]
function Math.Round(number, decimalPlaces)
	decimalPlaces = decimalPlaces or 1
	local rounded = math.round(number * 10 ^ decimalPlaces) * 10 ^ -decimalPlaces
	return rounded
end

function Math.RoundWithoutError(number, decimalPlaces)
	return Math.ClearFloatingPointError(Math.Round(number, decimalPlaces), decimalPlaces)
end

function Math.Lerp(start, goal, alpha)
	return start + (goal - start) * alpha
end

function Math.LerpAngle(start, goal, alpha)
	while start > TAU do
		start -= TAU
	end

	while start < 0 do
		start += TAU
	end

	while goal > TAU do
		goal -= TAU
	end

	while goal < 0 do
		goal += TAU
	end

	local diff = goal - start

	local newAngle = start

	if math.abs(diff) < math.pi then
		newAngle += diff * alpha
	else

		local newDiff = (TAU - math.abs(diff))

		if diff > 0 then
			newDiff *= -1
		end

		newAngle += newDiff * alpha
	end

	return newAngle
end

function Math.LerpCFrame(start, goal, alpha)
	return start:Lerp(goal, alpha)
end

return Math