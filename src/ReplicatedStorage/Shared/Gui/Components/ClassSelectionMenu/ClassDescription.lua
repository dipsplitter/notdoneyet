local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local UiFramework = Framework.GetShared("UiFramework")
local AssetService = Framework.GetShared("AssetService")

local Tooltip = UiFramework.GetElement("Tooltip")

local screenGui = UiFramework.GetScreenGui("ClassSelectionMenu")
local classDescriptionUi = screenGui.ClassDescription
local classDescriptionResource = UiFramework.GetResource("ClassDescription")
UiFramework.ApplyResource(classDescriptionUi, classDescriptionResource)

local classImageUi = screenGui.ClassImage
local classTipsUi = classDescriptionUi.ClassTips
local classRoleIconsUi = classDescriptionUi.ClassRoleIcons

local templatesFolder = classDescriptionUi.Templates
local roleIcon = templatesFolder.ClassRoleIcon
local playstyleIcon = templatesFolder.ClassPlaystyleIcon
local tooltip = templatesFolder.Tooltip

local iconsCache = {}
local tooltipsCache = {}

for roleName, data in AssetService.Images(`Classes.Roles`) do
	local newIcon = roleIcon:Clone()
	iconsCache[roleName] = newIcon
	newIcon.RoleImage.Image = data.Id
end

for playstyleName, data in AssetService.Images(`Classes.Playstyles`) do
	local newIcon = playstyleIcon:Clone()
	iconsCache[playstyleName] = newIcon
	newIcon.PlaystyleImage.Image = data.Id
end

for iconName, iconObject in iconsCache do
	local newTooltip = Tooltip.new({
		Trigger = iconObject,
		Ui = tooltip:Clone(),
		Parent = screenGui,
		MouseOffset = classDescriptionResource.Config.TooltipOffset
	})
	
	newTooltip.Ui.TooltipHeader.Text = iconName
	newTooltip.Ui.TooltipDescription.Text = classDescriptionResource.Config.RolesText[iconName]
	tooltipsCache[iconsCache] = newTooltip
end

local function ClearRoleIcons()
	for i, icon in classRoleIconsUi:GetChildren() do
		if not icon:IsA("Frame") then
			continue
		end
		
		icon.Parent = nil
	end
end

local function SetOverview(classConfig)
	local textLines = classConfig.Overview
	classDescriptionUi.ClassOverviewLabel.Text = textLines
end

local function SetClassImage(className)
	classImageUi.Image = AssetService.Images(`Classes.ClassSelectRender.{className}`).Id
end

local function SetIcons(classConfig)
	local roles = classConfig.Roles
	for i, roleName in roles do
		local icon = iconsCache[roleName]
		icon.Visible = true
		icon.Parent = classRoleIconsUi
	end

	local playstyles = classConfig.Playstyles
	for i, playstyleName in playstyles do
		local icon = iconsCache[playstyleName]
		icon.Visible = true
		icon.Parent = classRoleIconsUi
	end
end 
local function SetTips(classConfig)
	local resultString = ""
	local tips = classConfig.Tips
	for i, tipString in tips do
		resultString = `{resultString}• {tipString}\n\n`
	end
	classTipsUi.Text = resultString:sub(1, #resultString - 2)
end

local UiComponent_ClassDescription = {}

function UiComponent_ClassDescription.SetClass(className)
	ClearRoleIcons()
	
	if not className then
		classDescriptionUi.Visible = false
		classImageUi.Image = ""
		classTipsUi.Text = ""
		return
	end

	classDescriptionUi.Visible = true
	classDescriptionUi.ClassNameLabel.Text = className
	
	local classConfig = classDescriptionResource.Config[className]

	SetOverview(classConfig)
	SetClassImage(className)
	SetIcons(classConfig)
	SetTips(classConfig)
end

return UiComponent_ClassDescription
