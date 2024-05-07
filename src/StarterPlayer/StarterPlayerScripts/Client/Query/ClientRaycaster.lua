local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local Raycaster = Framework.GetShared("Raycaster")

local Client = Framework.GetClient("Client")

local ClientRaycaster = {}
ClientRaycaster.__index = ClientRaycaster
ClientRaycaster.ClassName = "ClientRaycaster"
setmetatable(ClientRaycaster, Raycaster)

function ClientRaycaster.new(params)
	local self = Raycaster.new(params)
	setmetatable(self, ClientRaycaster)
	
	self:AddToIgnoreList(workspace.ItemModels) -- TODO: Do something better
	if Client.Character then
		self:AddToIgnoreList(Client.Character)
	end
	
	self:AddConnections({
		CharacterAdded = Client.CharacterAddedSignal:Connect(function(char)
			self:AddToIgnoreList(char)
		end)
	})
	
	return self
end

function ClientRaycaster:CastToMouse(length)
	local mouseRay = Client.GetHeadToMouseRay()
	return self:Cast(mouseRay.Origin, mouseRay.Direction, length)
end

function ClientRaycaster:CastFromEyes(direction, length)
	local mouseRay = Client.GetHeadToMouseRay()
	return self:Cast(mouseRay.Origin, direction, length)
end

function ClientRaycaster:BlockcastToMouse(length, size)
	if not size then
		local characterSize = Client.Character.PrimaryPart.BoundingBox.Size
		size = Vector3.new(characterSize.X, characterSize.Y, 0)
	else
		size.Z = 0
	end
	
	local mouseRay = Client.GetHeadToMouseRay()
	
	return self:Blockcast(Client.Character:GetPivot(), size, mouseRay.Direction * length)
end

return ClientRaycaster
