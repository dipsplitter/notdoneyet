local StructuresFolder = script.Parent.Structures

local enumToStructure = {}
local structureToEnum = {}
local structures = {}

-- Indexes declared structures so that they can be sent through the network if the client does not know the structure
local DT_StructureRetriever = {}

function DT_StructureRetriever.ToEnum(cacheName, structureName)
	-- One concatenated string
	if not structureName then
		return structureToEnum[cacheName]
	end
	
	-- Concatenate them
	return structureToEnum[`{cacheName}.{structureName}`]
end

function DT_StructureRetriever.ToStructureName(number)
	return enumToStructure[number]
end

function DT_StructureRetriever.ToStructureTable(id)
	if type(id) == "number" then
		id = DT_StructureRetriever.ToStructureName(id)
	end
	
	return structures[id]
end

for i, moduleScript in StructuresFolder:GetChildren() do
	local contents = require(moduleScript)
	
	local cacheName = contents.Name
	
	for structureName, structure in contents.Cache do
		local structureId = `{cacheName}.{structureName}`
		
		table.insert(enumToStructure, structureId)
		structures[structureId] = structure
	end
end
table.sort(enumToStructure)

-- Fill reverse lookup
for id, structureId in enumToStructure do
	structureToEnum[structureId] = id
end

return DT_StructureRetriever
