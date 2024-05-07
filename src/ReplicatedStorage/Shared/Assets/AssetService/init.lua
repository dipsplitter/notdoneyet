local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local TableUtilities = Framework.GetShared("TableUtilities")
local RecycledSpawn = Framework.GetShared("RecycledSpawn")
local RbxAssets = Framework.GetShared("RbxAssets")
local Signal = Framework.GetShared("Signal")

local CreateAssetInstance = require(script.CreateAssetInstance)

local ContentProvider = game:GetService("ContentProvider")

local AssetsFolder = script.Parent

local data = {
	Sounds = {},
	Animations = {},
	Images = {},
}

local folders = {}

for i, folder in AssetsFolder:GetChildren() do
	if not folder:IsA("Folder") then
		continue
	end
	
	if not data[folder.Name] then
		continue
	end
	
	folders[folder.Name] = folder.Storage
end

local function RetrieveAllFromModule(moduleScript)
	local pathsDictionary = {}

	local function Recurse(pathTable, currentTable)
		for key, subTable in currentTable do
			local newPath = table.clone(pathTable)
			table.insert(newPath, key)

			if type(subTable) ~= "table" then
				return
			end

			-- Keep going
			if not subTable.Id then
				-- Check next level
				local k, v = next(subTable)

				-- Add the asset group as a whole
				if v.Id then
					pathsDictionary[table.concat(newPath, ".")] = subTable
				end

				-- Also add each group element
				Recurse(table.clone(newPath), subTable)
			else
				pathsDictionary[table.concat(newPath, ".")] = subTable
			end

		end
	end

	local moduleTable = require(moduleScript)
	
	Recurse({moduleScript.Name}, moduleTable)

	return pathsDictionary
end

local AssetService = {
	AssetsCached = Signal.new(),
}

function AssetService.Preload(category)
	local startTime = os.clock()
	
	local categoryAssets = data[category]
	local instances = {}
	
	for name, data in categoryAssets do
		local id = data.Id
		local success, err = pcall(function()
			id = RbxAssets.ToRbxAssetId(id)
		end)

		if not success then
			continue
		end
		
		local object = CreateAssetInstance[category](id)

		table.insert(instances, object)
	end
	
	local failedAssets = 0
	
	ContentProvider:PreloadAsync(instances, function(assetId, assetFetchStatus)
		if assetFetchStatus == Enum.AssetFetchStatus.Success then
			return
		end
		
		failedAssets += 1
	end)
	
	local debugPrint = `[ContentProvider ({category})]: Finished preloading {#instances} assets in {os.clock() - startTime} seconds.`
	if failedAssets > 0 then
		debugPrint ..= ` WARNING: {failedAssets} assets failed to load.`
	end
	print(debugPrint)
	
	-- Cleanup instances
	for i, instance in instances do
		instance:Destroy()
	end
	table.clear(instances)
end

function AssetService.PreloadAll()
	for category in data do
		RecycledSpawn(AssetService.Preload, category)
	end
end

-- Generate functions for each category
for assetCategory in data do
	-- Given the path, returns the associated data table
	AssetService[assetCategory] = function(path)
		local retrieved = data[assetCategory][path]
		
		if retrieved then
			return table.clone(retrieved)
		else
			return {Id = ""}
		end
	end
	
	-- Get the entire asset table of this category
	AssetService[`GetAll{assetCategory}`] = function()
		return data[assetCategory]
	end
end

-- Add everything to the cache
for name, folder in folders do
	
	RecycledSpawn(function()
		for i, module in folder:GetDescendants() do
			if not module:IsA("ModuleScript") then
				continue
			end

			local assets = RetrieveAllFromModule(module)
			TableUtilities.Merge(data[name], assets)
			
			AssetService.AssetsCached:Fire(name)
		end
	end)

end

return AssetService
