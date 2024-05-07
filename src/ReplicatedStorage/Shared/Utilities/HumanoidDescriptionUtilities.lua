local MarketplaceService = game:GetService("MarketplaceService")

local ColoredBodyParts = {
	Head = 0,
	LeftArm = 0,
	LeftLeg = 0,
	RightArm = 0,
	RightLeg = 0,
	Torso = 0,
}
local HumanoidDescriptionScalePropertyMap = {
	["BodyProportionScale"] = "ProportionScale",
	["BodyDepthScale"] = "DepthScale",
	["BodyWidthScale"] = "WidthScale",
	["BodyHeightScale"] = "HeightScale",
}


local HumanoidDescriptionUtilities = {}

function HumanoidDescriptionUtilities.GenerateFromModel(model)
	local humanoidDescription = Instance.new("HumanoidDescription")
	local humanoid = model.Humanoid
	
	-- BODY COLORS
	local bodyColors = model:FindFirstChildWhichIsA("BodyColors")
	for bodyPart in ColoredBodyParts do
		humanoidDescription[`{bodyPart}Color`] = bodyColors[`{bodyPart}Color3`]
	end
	
	-- PROPORTIONS AND SCALE
	for i, object in humanoid:GetChildren() do
		if not object:IsA("NumberValue") then
			continue
		end

		local property = HumanoidDescriptionScalePropertyMap[object.Name]
		if not property then
			property = object.Name
		end

		humanoidDescription[property] = object.Value
	end
	
	-- ACCESSORIES
	for i, child in model:GetChildren() do
		if not child:IsA("Accessory") then
			continue
		end
		
		local descendants = child:GetDescendants()

	end
	
	-- SHIRTS, PANTS, ETC.
	local pants = model:FindFirstChildWhichIsA("Pants")
	local shirt = model:FindFirstChildWhichIsA("Shirt")
	local shirtGraphic = model:FindFirstChildWhichIsA("ShirtGraphic")

	if pants then
		humanoidDescription.Pants = pants.PantsTemplate
	end

	if shirt then
		humanoidDescription.Shirt = shirt.ShirtTemplate
	end

	if shirtGraphic then
		humanoidDescription.GraphicTShirt = shirtGraphic.Graphic
	end
	
	return humanoidDescription
end

return HumanoidDescriptionUtilities