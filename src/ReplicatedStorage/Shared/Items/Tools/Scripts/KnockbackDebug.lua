local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local MeleeWeapon = Framework.GetShared("MeleeWeapon")
local WeaponAttacks = Framework.GetShared("WeaponAttacks")
local ActionManagerConnector = Framework.GetShared("ActionManagerConnector")

local Client = Framework.GetClient("Client")

local BaseTool = if Framework.IsServer then Framework.GetServer("BaseTool") else Framework.GetClient("BaseTool")

local RunService = game:GetService("RunService")

local KnockbackDebug = {
	Client = {
		Primary = {
			Started = function(item)
				local p = Instance.new("Part")
				p.Size = Vector3.new(1, 1, 1)
				--p.CollisionGroup = "Projectile"

				local rayInfo = Client.GetHeadToMouseRay()
				rayInfo.Origin = Client.Character.Head.Position

				p.CFrame = CFrame.lookAt(rayInfo.Origin, rayInfo.Origin + rayInfo.Direction)
				p.CanCollide = false
				
				local attachment = Instance.new("Attachment")
				attachment.Parent = p
				
				local linearVelocity = Instance.new("LinearVelocity")
				linearVelocity.MaxForce = math.huge
				linearVelocity.VectorVelocity = p.CFrame.LookVector * 120
				linearVelocity.Attachment0 = attachment
				linearVelocity.Parent = p
				linearVelocity.Enabled = true
				
				p.Parent = workspace.Projectiles
			
				local connection
				connection = p.Touched:Connect(function(part)
					if part:IsDescendantOf(item.Character) then
						return
					end

					local position = p.Position
					local primaryPartPosition = item.Character.PrimaryPart.Position - Vector3.new(0, 1, 0)
					local direction = primaryPartPosition - position
						
					local range = direction.Magnitude

					p:Destroy()
					connection:Disconnect()
						
					if range > 14 then
						return
					end

					local knockbackForce = direction.Unit * 90
					Client.ApplyImpulse(knockbackForce)
				end)
			end,
		}
	},
	
	Shared = {
		Equip = {
			Ended = function(item)
				item.ActionManager:Bind("Primary")
			end,
		},

		Unequip = function(item)
			item.ActionManager:Cancel("Primary")
		end,
	},
}

function KnockbackDebug.new(params)
	params.Id = params.Id or "BoostGun"

	local item = BaseTool.new(params)
	
	ActionManagerConnector.Declare(item, KnockbackDebug)
	
	return item
end

return KnockbackDebug
