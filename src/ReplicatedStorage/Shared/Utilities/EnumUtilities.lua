local ENUM_KEYCODE_ZERO_VALUE = Enum.KeyCode.Zero.Value

local EnumUtilities = {
	KeyCodeNames = {
		"Zero",
		"One",
		"Two",
		"Three",
		"Four",
		"Five",
		"Six",
		"Seven",
		"Eight",
		"Nine",
	}
}

function EnumUtilities.NumberToKeyCode(number)
	if number < 0 or number > 9 then
		warn(`NumberToKeyCode only accepts integers from 0 to 9; number received: {number}`)
		return
	end
	
	return EnumUtilities.KeyCodeNames[number + 1]
end

function EnumUtilities.KeyCodeToNumber(keyCode)
	if typeof(keyCode) == "string" then
		keyCode = Enum.KeyCode[keyCode]
	end
	
	if keyCode.Value < ENUM_KEYCODE_ZERO_VALUE or keyCode.Value > ENUM_KEYCODE_ZERO_VALUE + 9 then
		return
	end
	
	return table.find(EnumUtilities.KeyCodeNames, keyCode.Name) - 1
end

return EnumUtilities
