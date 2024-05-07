--!native

-- 10 mantissa bits is approximately 3 digits of precision
local BITS = {
	[16] = {5, 10},
	[32] = {7, 23},
}

local DEFAULT_EXPONENT_BITS = 5

local FloatUtilities = {
	NORMAL_BITS = 11
}

function FloatUtilities.GetExponentMantissaBits(bitsInfo)
	-- We declared exponent and mantissa bits in an array
	if type(bitsInfo) == "table" then
		return bitsInfo[1], bitsInfo[2]
	end
	
	local defaultBits = BITS[bitsInfo]
	if defaultBits then
		return defaultBits[1], defaultBits[2]
	end
	
	local exp = 2
	
	if bitsInfo >= 24 then
		exp = 6
	elseif bitsInfo > 16 then
		exp = 5
	elseif bitsInfo >= 8 then
		exp = 4
	end
	
	return exp, bitsInfo - exp - 1
end

function FloatUtilities.Read(bits, exponentBits, mantissaBits)
	local signBit = bit32.btest(bits, 2 ^ (exponentBits + mantissaBits))
	local exponent = bit32.extract(bits, mantissaBits, exponentBits)
	local mantissa = bit32.extract(bits, 0, mantissaBits)

	local bias = (2 ^ (exponentBits - 1)) - 1

	if exponent == bias then
		if mantissa ~= 0 then
			return (0 / 0)
		else
			return (if signBit then -math.huge else math.huge)
		end

	elseif exponent == 0 then

		if mantissa == 0 then
			return 0
		else
			local value = math.ldexp(mantissa / 2 ^ mantissaBits, -(bias - 1))

			return (if signBit then -value else value)
		end

	end

	mantissa = (mantissa / 2 ^ mantissaBits) + 1

	local value = math.ldexp(mantissa, exponent - bias)
	return (if signBit then -value else value)

end

function FloatUtilities.Write(number, exponentBits, mantissaBits)
	local result = 0
	local signBit = number < 0

	number = math.abs(number)
	result += bit32.lshift(if signBit then 1 else 0, mantissaBits + exponentBits)

	local mantissa, exponent = math.frexp(number)

	local bias = (2 ^ (exponentBits - 1)) - 1

	-- Infinity: exponent is all 1s, mantissa all 0s
	if number == math.huge then
		-- Positive and negative infinities differ by sign bit
		local exp = 2 ^ exponentBits - 1
		result += bit32.lshift(exp, mantissaBits)

		return result
	elseif number ~= number or number == 0 then -- NaN or 0
		return 0
	elseif exponent + bias <= 1 then -- Too small, so the exponent is 0
		mantissa = math.floor(mantissa * 2 ^ mantissaBits + 0.5)
		result += mantissa

		return result
	end

	mantissa = math.floor((mantissa - 0.5) * 2 ^ (mantissaBits + 1) + 0.5)

	result += bit32.lshift(exponent + bias - 1, mantissaBits) + mantissa

	return result
end

-- Normals are represented by 10 bits and 1 sign bit
-- 3 decimal precision
function FloatUtilities.WriteNormal(normal)
	normal = math.clamp(normal, -1, 1)
	
	-- Between -1000 and 1000
	normal = normal * 1000
	
	normal = math.round(normal)
	
	return normal
end

function FloatUtilities.ReadNormal(encoded)
	if bit32.extract(encoded, FloatUtilities.NORMAL_BITS - 1, 1) == 1 then
		encoded -= 2 ^ FloatUtilities.NORMAL_BITS
	end

	return encoded / 1000
end

return FloatUtilities