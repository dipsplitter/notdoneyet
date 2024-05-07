local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local UiFramework = Framework.GetShared("UiFramework")
local UiViewHandler = Framework.GetShared("UiViewHandler")

local menus = {
	Main = nil,
	ClassSelection = require(script.ClassSelection),
}

local enabledMenus = {}

local Menu = {}

return Menu
