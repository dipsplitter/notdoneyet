local White = Color3.new(255, 255, 255)

local ColorUtilities = {}

function ColorUtilities.Invert(color)
	return Color3.fromRGB(255 - color.R, 255 - color.G, 255 - color.B)
end

function ColorUtilities.FromRGBA(r, g, b, a)
	local color = Color3.new(r, g, b)
	return color:Lerp(White, a)
end

function ColorUtilities.AreEqual(a, b, epsilon)
	if not epsilon then
		epsilon = 1e-6
	end

	return math.abs(a.R - b.R) <= epsilon
		and math.abs(a.G - b.G) <= epsilon
		and math.abs(a.B - b.B) <= epsilon
end

return ColorUtilities
