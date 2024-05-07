return function(componentTable)
	local uiType = componentTable.Type or "Frame"
	
	local gui = Instance.new(uiType)
	
	-- Borders should be disabled by default !! They are SO ugly !!!
	if gui:IsA("GuiObject") then
		gui.BorderSizePixel = 0
	end
	
	-- Clear text from text UIs
	if gui:IsA("TextLabel") or gui:IsA("TextBox") or gui:IsA("TextButton") then
		gui.Text = ""
	end
	
	-- Clear the default image
	if gui:IsA("ImageLabel") or gui:IsA("ImageButton") then
		gui.Image = ""
	end
	
	return gui
end
