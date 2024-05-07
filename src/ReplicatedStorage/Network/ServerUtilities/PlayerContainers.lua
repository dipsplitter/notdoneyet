local Players = game:GetService("Players")

local function ParsePlayersList(...)
	local args = {...}
	local playersList = {}

	-- An array of players
	local tab = args[1]
	if type(tab) == "table" and tab[1] then
		for i, player in tab do
			playersList[player] = true
		end
	else -- We passed players as a tuple
		for i, player in args do
			playersList[player] = true
		end
	end
	
	return playersList
end

local PlayerContainers = {}
PlayerContainers.__index = PlayerContainers

function PlayerContainers:Players()
	local targets = self.Targets
	local targetType = self.Type
	local players = {}
	local clients = Players:GetPlayers()

	if targetType == "Single" then

		table.insert(players, targets)

	elseif targetType == "All" then

		return clients

	elseif targetType == "Except" then

		for i, player in clients do
			if targets[player] then
				continue
			end

			table.insert(players, player)
		end

	elseif targetType == "Some" then

		for i, player in targets do
			if clients[player] then
				table.insert(players, player)
			end
		end

	end

	return players
end

function PlayerContainers:IsInContainer(player)
	return table.find(self:Players(), player)
end

function PlayerContainers.All()
	return setmetatable(
		{Type = "All"}, 
		PlayerContainers)
end

function PlayerContainers.Single(player)
	return setmetatable(
		{Type = "Single", Targets = player}, 
		PlayerContainers)
end

function PlayerContainers.Some(...)
	return setmetatable(
		{Type = "Some", Targets = ParsePlayersList(...)}, 
		PlayerContainers)
end

function PlayerContainers.Except(...)
	return setmetatable(
		{Type = "Except", Targets = ParsePlayersList(...)},
		PlayerContainers)
end

return PlayerContainers
