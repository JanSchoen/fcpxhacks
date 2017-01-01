local log								= require("hs.logger").new("timline")
local inspect							= require("hs.inspect")

local just								= require("hs.just")
local axutils							= require("hs.finalcutpro.axutils")

local PrimaryWindow						= require("hs.finalcutpro.main.PrimaryWindow")
local SecondaryWindow					= require("hs.finalcutpro.main.SecondaryWindow")
local Button							= require("hs.finalcutpro.ui.Button")
local Table								= require("hs.finalcutpro.ui.Table")
local ScrollArea						= require("hs.finalcutpro.ui.ScrollArea")
local CheckBox							= require("hs.finalcutpro.ui.CheckBox")
local PopUpButton						= require("hs.finalcutpro.ui.PopUpButton")
local TextField							= require("hs.finalcutpro.ui.TextField")

local GeneratorsBrowser = {}

GeneratorsBrowser.TITLE = "Titles and Generators"

function GeneratorsBrowser:new(parent)
	o = {_parent = parent}
	setmetatable(o, self)
	self.__index = self
	return o
end

function GeneratorsBrowser:parent()
	return self._parent
end

function GeneratorsBrowser:app()
	return self:parent():app()
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--- GeneratorsBrowser UI
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function GeneratorsBrowser:UI()
	if self:isShowing() then
		return axutils.cache(self, "_ui", function()
			return self:parent():UI()
		end)
	end
	return nil
end

function GeneratorsBrowser:isShowing()
	return self:parent():showGenerators():isChecked()
end

function GeneratorsBrowser:show()
	local menuBar = self:app():menuBar()
	-- Go there direct
	menuBar:checkMenu("Window", "Go To", GeneratorsBrowser.TITLE)
	return self
end

function GeneratorsBrowser:hide()
	self:parent():hide()
	return self
end

-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-- Sections
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------

function GeneratorsBrowser:mainGroupUI()
	return axutils.cache(self, "_mainGroup",
	function()
		local ui = self:UI()
		return ui and axutils.childWithRole(ui, "AXSplitGroup")
	end)
end

function GeneratorsBrowser:sidebar()
	if not self._sidebar then
		self._sidebar = Table:new(self, function()
			return axutils.childWithID(self:mainGroupUI(), "_NS:9")
		end)
	end
	return self._sidebar
end

function GeneratorsBrowser:contents()
	if not self._contents then
		self._contents = ScrollArea:new(self, function()
			local group = axutils.childWithRole(self:mainGroupUI(), "AXGroup")
			return group and group[1]
		end)
	end
	return self._contents
end

function GeneratorsBrowser:group()
	if not self._group then
		self._group = PopUpButton:new(self, function()
			return axutils.childWithRole(self:UI(), "AXPopUpButton")
		end)
	end
	return self._group
end

function GeneratorsBrowser:search()
	if not self._search then
		self._search = TextField:new(self, function()
			return axutils.childWithRole(self:mainGroupUI(), "AXTextField")
		end)
	end
	return self._search
end

function GeneratorsBrowser:showSidebar()
	self:app():menuBar():checkMenu("Window", "Show in Workspace", "Sidebar")
end

function GeneratorsBrowser:topCategoriesUI()
	return self:sidebar():rowsUI(function(row)
		return row:attributeValue("AXDisclosureLevel") == 0
	end)
end

function GeneratorsBrowser:showAllTitles()
	self:showSidebar()
	local topCategories = self:topCategoriesUI()
	if topCategories and #topCategories == 2 then
		self:sidebar():selectRow(topCategories[1])
	end
	return self
end

function GeneratorsBrowser:showAllGenerators()
	self:showSidebar()
	local topCategories = self:topCategoriesUI()
	if topCategories and #topCategories == 2 then
		self:sidebar():selectRow(topCategories[2])
	end
	return self
end

function GeneratorsBrowser:saveLayout()
	local layout = {}
	layout.sidebar = self:sidebar():saveLayout()
	layout.contents = self:contents():saveLayout()
	layout.search = self:search():saveLayout()
	return layout
end

function GeneratorsBrowser:loadLayout(layout)
	if layout then
		self:search():loadLayout(layout.search)
		self:sidebar():loadLayout(layout.sidebar)
		self:contents():loadLayout(layout.contents)
	end
end

return GeneratorsBrowser