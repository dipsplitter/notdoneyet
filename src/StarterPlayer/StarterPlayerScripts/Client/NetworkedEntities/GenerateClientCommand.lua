local UserInputService = game:GetService("UserInputService")

local camera = workspace.CurrentCamera

local currentCommandId = 0

return function(currentTick, latestSnapshotTick)
	local cameraLookVector = camera.CFrame.LookVector

	local command = {
		Id = currentCommandId,
		Tick = currentTick,
		LatestUpdateTick = latestSnapshotTick or 0,
		--HeadPitch = math.atan(cameraLookVector.Y / math.cos(math.asin(cameraLookVector.Y))),
		--HeadYaw = math.atan2(cameraLookVector.Z, -cameraLookVector.X) + math.pi / 2,
	}

	currentCommandId += 1

	return command
end
