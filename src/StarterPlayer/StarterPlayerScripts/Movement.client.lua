local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))

local Globals = Framework.GetShared("Globals")

local CharacterMovementController = Framework.GetShared("CharacterMovementController")
local Client = Framework.GetClient("Client")

local NETWORK = Framework.Network()
local VelocityEvent = NETWORK.Event("Velocity")

local localPlayer = Players.LocalPlayer

-- Disable the default controls !!!
local controls = require(localPlayer.PlayerScripts.PlayerModule):GetControls()
controls:Disable()

local movementController = CharacterMovementController.new(localPlayer.Character, Client.GetInputHandler())
movementController:Start()

Client.MovementController = movementController

localPlayer.CharacterAdded:Connect(function(character)
	movementController:SetCharacter(character)
end)

VelocityEvent:Connect(function(args)
	local character = localPlayer.Character
	if not character then
		return
	end

	local velocity = args.Vector
	
	movementController:ApplyImpulse(velocity / Globals.DefaultBoundingBoxVolume)
end)