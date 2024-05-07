--!native
local TableUtilities = {}

function TableUtilities.RecursiveFind(tab, requestedKey)
	for key, value in pairs(tab) do
		if key == requestedKey then
			return tab[key]
		end

		if type(value) == "table" then
			return TableUtilities.RecursiveFind(value, requestedKey)
		end
	end
end

function TableUtilities.RecursiveFindAll(tab, requestedKey)
	local foundValues = {}
	
	local function TraverseTable(tab)
		for key, value in pairs(tab) do
			if key == requestedKey then
				table.insert(foundValues, value)
			elseif type(value) == "table" then
				TraverseTable(value)
			end
		end
	end
	
	TraverseTable(tab)
	return foundValues
end

-- Go through each table in
function TableUtilities.RecursiveTraverse(tab, callback)
	
	local function TraverseTable(tab)
		for key, value in pairs(tab) do
			callback(key, value)
			
			if type(value) == "table" then
				TraverseTable(value)
			end
		end
	end
	
	TraverseTable(tab)
end

function TableUtilities.RecursiveFreeze(tab)
	if type(tab) == "table" and table.isfrozen(tab) then
		return
	end
	
	table.freeze(tab)
	
	for k, v in tab do
		if type(v) == "table" then
			TableUtilities.RecursiveFreeze(v)
		end
	end
end

function TableUtilities.Copy(tab)
	local newTab = {}

	for k, v in pairs(tab) do
		newTab[k] = v
	end

	return newTab
end

function TableUtilities.DeepCopy(tab)
	local newTab = table.clone(tab)
			
	for k, v in tab do
		if type(v) == "table" then
			newTab[k] = TableUtilities.DeepCopy(v)
		end
	end

	return newTab
end

function TableUtilities.CompareArrays(a1, a2)
	if #a1 ~= #a2 then
		return false
	end

	for i, v in ipairs(a1) do
		if v ~= a2[i] then
			return false
		end
	end
	return true
end

function TableUtilities.DeepCompareArrays(a1, a2)
	if #a1 ~= #a2 then
		return false
	end
	
	for i, v in ipairs(a1) do
		if type(v) == "table" then
			if not TableUtilities.DeepCompareArrays(v, a2[i]) then
				return false
			end
		else
			if v ~= a2[i] then
				return false
			end
		end
	end
	
	return true
end

function TableUtilities.StringPathToArray(path)
	if type(path) == "table" then
		return path
	end
	
	local pathArray = {}
	if path ~= "" then
		for s in string.gmatch(path, "[^%./]+") do
			table.insert(pathArray, s)
		end
	end
	return pathArray
end

function TableUtilities.ArrayToStringPath(path)
	if type(path) == "string" then
		return path
	end
	
	return table.concat(path, ".")
end

function TableUtilities.TraverseWithPath(tab, path)
	path = TableUtilities.StringPathToArray(path)
	
	local pointer = tab
	
	for i = 1, #path - 1 do
		local nextItem = pointer[path[i]]
		
		if not nextItem then
			pointer[path[i]] = {}
		end

		pointer = pointer[path[i]]
	end
	
	return pointer, path[#path]
end

-- The difference is the "-1"
function TableUtilities.GetValueFromPath(tab, path)
	path = TableUtilities.StringPathToArray(path)

	local pointer = tab

	for i = 1, #path do
		local nextItem = pointer[path[i]]

		if not nextItem then
			pointer[path[i]] = {}
		end

		pointer = pointer[path[i]]
	end

	return pointer
end

function TableUtilities.GetKeyCount(dict)
	local count = 0
	for k, v in dict do
		count += 1
	end
	
	return count
end

function TableUtilities.Merge(original, merger, override)
	override = (override == nil) or override
	for k, v in merger do
		if original[k] and override == false then
			continue
		end
		
		original[k] = v
	end
	
	return original
end

function TableUtilities.MergeArrays(a, b)
	local result = table.clone(a)
	table.move(b, 1, #b, #result + 1, result)
	return result
end

function TableUtilities.Reconcile(original, reconcile)
	local tbl = table.clone(original)

	for key, value in reconcile do
		if tbl[key] == nil then
			
			if type(value) == "table" then
				tbl[key] = TableUtilities.DeepCopy(value)
			else
				tbl[key] = value
			end
			
		elseif type(reconcile[key]) == "table" then
			
			if type(value) == "table" then
				tbl[key] = TableUtilities.Reconcile(value, reconcile[key])
			else
				tbl[key] = TableUtilities.DeepCopy(reconcile[key])
			end
			
		end
	end

	return tbl
end

function TableUtilities.DeepMerge(original, merger)
	local tab = TableUtilities.DeepCopy(original)
	
	for key, value in merger do
		if type(value) == "table" then
			if type(tab[key]) == "table" then
				tab[key] = TableUtilities.DeepMerge(tab[key], value)
			else
				tab[key] = TableUtilities.DeepCopy(value)
			end
		else
			tab[key] = value
		end
	end

	return tab
end

function TableUtilities.IsArray(tab)
	if type(tab) ~= "table" then
		return false
	end
	
	local count = 0
	for key in tab do
		count += 1
	end
	return count == #tab
end

function TableUtilities.IsDictionary(tab)
	if type(tab) ~= "table" then
		return false
	end
	
	local count = 0
	for key in tab do
		count += 1
	end
	return count ~= #tab
end

function TableUtilities.IsFlat(tab)
	for k, v in tab do
		if type(v) == "table" then
			return false
		end
	end
	return true
end

function TableUtilities.Keys(dict)
	local keyArray = {}

	for key in pairs(dict) do
		table.insert(keyArray, key)
	end

	return keyArray
end

function TableUtilities.Values(dict)
	local valueArray = {}

	for key, value in pairs(dict) do
		table.insert(valueArray, value)
	end

	return valueArray
end

--[[	
	Elements for which the callback does not return true will not be included in the array
]]
function TableUtilities.Filter(arr, callback, ...)
	if not callback then
		return arr
	end
	
	local results = {}

	for key, value in arr do
		if callback(value, ...) then
			table.insert(results, value)
		end
	end

	return results
end

function TableUtilities.FilterDictionary(dict, callback)
	if not callback then
		return dict
	end

	local results = {}

	for key, value in dict do
		if callback(key, value) then
			results[key] = value
		end
	end

	return results
end


--[[
	If one element passes the callback, return true
]]
function TableUtilities.Some(tab, callback)
	for key, value in pairs(tab) do
		if callback(value) then
			return true, key
		end
	end
	return false
end

--[[
	Requires every element to pass the callback to return true
]]
function TableUtilities.Every(tab, callback)
	for key, value in pairs(tab) do
		if not callback(key, value) then
			return false, key
		end
	end
	return true
end

--[[
	{
		A = {
			B = 5,
			C = 10,
		}
		
		=>
		
		A.B = 5,
		A.C = 10,
	}
]]


local function TableContainsBlacklistedKeys(tab, blacklist)
	if not blacklist then
		return false
	end
	
	for i, blacklistedKey in blacklist do
		if tab[blacklistedKey] then
			return true
		end
	end

	return false
end

function TableUtilities.Flatten(tab, prefix, blacklist)
	prefix = prefix or ""
	local result = {}

	for key, value in tab do
		local newKey = prefix ~= "" and (prefix .. "." .. key) or key

		if type(value) == "table" and not TableContainsBlacklistedKeys(value, blacklist) then
			
			-- Recursively flatten nested tables
			local flattened = TableUtilities.Flatten(value, newKey, blacklist)
			for k, v in flattened do
				result[k] = v
			end
			
		else
			result[newKey] = value
		end
	end

	return result
end

function TableUtilities.FlattenWithArrayPaths(tab, currentPath, blacklist)
	currentPath = currentPath or {}
	local result = {}

	for key, value in tab do
		local path = table.clone(currentPath)
		table.insert(path, key)

		if type(value) == "table" and not TableContainsBlacklistedKeys(value, blacklist) then
			
			local flattened = TableUtilities.FlattenWithArrayPaths(value, path, blacklist)
			for k, v in flattened do
				result[k] = v
			end
			
		else
			result[path] = value
		end
	end

	return result
end

-- Reverses Util.Flatten
function TableUtilities.ToNested(input)
	if not TableUtilities.IsNested(input) then
		return input
	end
	
	local result = {}

	for key, value in pairs(input) do
		local levels = {}
		for level in key:gmatch("[^.]+") do
			table.insert(levels, level)
		end

		local function InsertNested(currentLevel, index)
			if index == #levels then
				currentLevel[levels[index]] = value
			else
				currentLevel[levels[index]] = currentLevel[levels[index]] or {}
				InsertNested(currentLevel[levels[index]], index + 1)
			end
		end

		InsertNested(result, 1)
	end

	return result
end

function TableUtilities.IsNested(input)
	for key, value in input do
		if type(value) == "table" then
			return true
		end
	end
	return false
end

function TableUtilities.CountNestedLevels(dictionary)
	local function CountLevelsHelper(dict, level)
		local maxLevel = level

		for key, value in pairs(dict) do
			if type(value) == "table" then
				local nestedLevel = CountLevelsHelper(value, level + 1)
				maxLevel = math.max(maxLevel, nestedLevel)
			end
		end

		return maxLevel
	end

	return CountLevelsHelper(dictionary, 1)
end

function TableUtilities.Intersection(arr1, arr2)
	local intersection = {}
	local lookup = {}
	for i, element in arr1 do
		lookup[element] = true
	end
	
	for i, element in arr2 do
		if lookup[element] then
			intersection[element] = true
		end
	end
	
	return intersection
end

return TableUtilities