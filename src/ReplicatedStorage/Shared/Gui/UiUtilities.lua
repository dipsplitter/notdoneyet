local GuiService = game:GetService("GuiService")
local GUI_INSET = GuiService:GetGuiInset()

local camera = workspace.CurrentCamera

local UiUtilities = {}

function UiUtilities.IsOnScreen(gui)
	local pos = gui.AbsolutePosition + GUI_INSET
	return pos.X + gui.X <= camera.ViewportSize.X and pos.X >= 0
		and pos.Y + gui.Y <= camera.ViewportSize.Y and pos.Y >= 0
end

function UiUtilities.IsInParent(gui)
	local parent = gui.Parent
	if not parent then
		return true
	end
	
	local thisAbsPos = gui.AbsolutePosition
	local thisAbsSize = gui.AbsoluteSize
	
	local parentAbsPos = parent.AbsolutePosition
	local parentAbsSize = parent.AbsoluteSize
	
	return thisAbsPos.X >= parentAbsPos.X and thisAbsPos.X + thisAbsSize.X <= parentAbsPos.X + parentAbsSize.X 
		and thisAbsPos.Y >= parentAbsPos.Y and thisAbsPos.Y + thisAbsSize.Y <= parentAbsPos.Y + parentAbsSize.Y
end

-- Returns the position such that the object does not exit the screen
function UiUtilities.ClampPosition(gui)
	local guiSize = gui.AbsoluteSize
	local guiPos = gui.AbsolutePosition
	
	local halfX = guiSize.X / 2
	local halfY = guiSize.Y / 2
	
	local centerX = guiPos.X + halfX
	local centerY = guiPos.Y + halfY
	
	
end

return UiUtilities
