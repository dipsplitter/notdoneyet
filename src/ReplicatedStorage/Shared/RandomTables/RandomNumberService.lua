local NUMBERS_GENERATED = 10000

local randomNumberGenerators = {
	"Projectile",
	"BulletSpread",
	"Tiebreak",
	
	"Random", -- All-purpose
}

local randomNumbers = {}

for i, generatorName in randomNumberGenerators do
	randomNumbers[generatorName] = {}

	local generator = Random.new(i)

	for i = 1, NUMBERS_GENERATED do
		table.insert(randomNumbers[generatorName], generator:NextNumber())
	end
end

local RandomNumberService = {}

return RandomNumberService
