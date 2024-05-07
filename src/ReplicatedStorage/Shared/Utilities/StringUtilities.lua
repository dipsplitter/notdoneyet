local StringUtilities = {}

function StringUtilities.UppercaseFirst(s)
	
end

function StringUtilities.SpaceTitle(str)
	return string.sub(string.gsub(str, "(%u)", " %1"), 2, -1)
end

function StringUtilities.SplitByCapital(str)
	return string.split(StringUtilities.SpaceTitle(str), " ")
end

function StringUtilities.TitlesHaveSameSuffix(str1, str2)
	local split1 = StringUtilities.SplitByCapital(str1)
	local split2 = StringUtilities.SplitByCapital(str2)
	
	return split1[#split1] == split2[#split2]
end

function StringUtilities.TitlesHaveSameLastWords(str1, str2, numWords)
	local split1 = StringUtilities.SplitByCapital(str1)
	local split2 = StringUtilities.SplitByCapital(str2)
	
	for i = 0, numWords - 1 do
		if split1[#split1 - 1] ~= split2[#split2 - 1] then
			return false
		end
	end
	
	return true
end

return StringUtilities
