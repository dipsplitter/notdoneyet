local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)

local Globals = Framework.GetShared("Globals")
local EntityService = Framework.GetShared("EntityService")

local EntitySimulation = Framework.GetClient("ClientEntitySimulation")

local InterpolateEntity = require(script.InterpolateEntity)

local ClientEntityRendering = {}

RunService.RenderStepped:Connect(function(deltaTime)
	local subTickTime = time() - EntitySimulation.PreviousTickTime
	
	local serverHistoryBuffer = EntityService.ServerHistoryBuffer
	
	local pastEntityStates = nil
	local snapshotNumber = 0
	local snapshotTick = 0

	for i, snapshot in serverHistoryBuffer.Array do
		if snapshot.Tick > EntitySimulation.Tick then
			continue
		end

		pastEntityStates = snapshot.States
		snapshotNumber = i
		snapshotTick = snapshot.Tick
	end
	
	-- Interpolate state
	local entityTableToRender = {}

	local timePast = ((EntitySimulation.Tick - snapshotTick) * Globals.TickRate) + subTickTime

	local nextSnapshot = serverHistoryBuffer[snapshotNumber + 1]
	
	if nextSnapshot then
		local timeApart = nextSnapshot.Tick - snapshotTick 
		local nextEntityStates = nextSnapshot.States

		local alpha = (timePast) / (timeApart * Globals.TickRate)

		for handle, pastState in pastEntityStates do
			local nextState = nextEntityStates[handle]
			if nextState then
				entityTableToRender[handle] = InterpolateEntity(pastState, nextState, handle)
			end
		end
	else
		-- Try to extrapolate???
		entityTableToRender = pastEntityStates
	end
end)

return ClientEntityRendering
