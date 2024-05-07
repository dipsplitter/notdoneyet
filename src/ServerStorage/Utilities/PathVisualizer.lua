local Waypoint = script.Waypoint
local ColorConfig = {
	Jump = Color3.fromRGB(29, 255, 37),
	End = Color3.fromRGB(255, 0, 0)
}

local PathVisualizer = {}

function PathVisualizer.VisualizeWaypoints(waypointsTable)
	local createdWaypointParts = {}
	
	for i, waypoint in ipairs(waypointsTable or {}) do
		local clone = Waypoint:Clone()
		clone.Position = waypoint.Position
		
		if waypoint == waypointsTable[#waypointsTable] then
			clone.Color = ColorConfig.End
		elseif waypoint.Action == Enum.PathWaypointAction.Jump then
			clone.Color = ColorConfig.Jump
		end
		
		clone.Parent = workspace
		table.insert(createdWaypointParts, clone)
	end
	
	return createdWaypointParts
end

return PathVisualizer
