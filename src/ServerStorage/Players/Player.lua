local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")

local Character = Framework.GetServer("Character")
local CharacterUtilities = Framework.GetServer("CharacterUtilities")

local Players = game:GetService("Players")

local Player = {}
Player.__index = Player
Player.ClassName = "Player"
setmetatable(Player, BaseClass)

function Player.new(playerObject)
	local self = BaseClass.new()
	setmetatable(self, Player)
	
	self.Player = playerObject
	self.UserId = playerObject.UserId

	self.Character = nil
	self.NextClass = nil
	
	task.spawn(function()
		local success, description = pcall(Players.GetHumanoidDescriptionFromUserId, Players, self.UserId)
		if not success then
			description = nil
		end
		
		self.Character = Character.new({
			Player = self.Player,
			Model = CharacterUtilities.CreateCharacterWithDescription(description),
			HumanoidDescription = description,
			Tags = {"Player"},
		})
		-- TODO
		self.Character:SetClass("Survivalist")
		
		self:AddConnections({
			CharacterDied = self.Character:ConnectTo("Died", function()
				-- TODO: RESPAWN (also error here)
				task.delay(2, function()
					self:SpawnCharacter()
				end)
				
				self.Signals.CharacterDied:Fire()
			end),
		})
		-- TODO
		self:SpawnCharacter()
	end)
	
	self:AddSignals("CharacterRemoving", "CharacterLoaded", "CharacterDied")
	
	self:AddConnections({
		CharacterAppearanceLoaded = self.Player.CharacterAppearanceLoaded:Connect(function()
			self.Signals.CharacterLoaded:Fire(self.Player.Character)
		end),
	})
	
	return self
end

function Player:SpawnCharacter()
	if self.NextClass then
		self.Character:SetClass(self.NextClass)
	end
	
	local success = pcall(function()
		self.Player:LoadCharacterWithHumanoidDescription(self.Character.Description.HumanoidDescription)
	end)
	
	if success then
		-- TODO: Spawning
		self.Character:Spawn(self.Player.Character, {Region = "PlayerSpawn"})
	end
end

-- TODO: Kill the player if they ticked the option to kill on class change
function Player:SetNextClass(nextClass)
	self.NextClass = nextClass
end

return Player
