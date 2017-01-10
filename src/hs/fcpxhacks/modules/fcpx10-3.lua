--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  			  ===========================================
--
--  			             F C P X    H A C K S
--
--			      ===========================================
--
--
--  Thrown together by Chris Hocking @ LateNite Films
--  https://latenitefilms.com
--
--  You can download the latest version here:
--  https://latenitefilms.com/blog/final-cut-pro-hacks/
--
--  Please be aware that I'm a filmmaker, not a programmer, so... apologies!
--
--------------------------------------------------------------------------------
--  LICENSE:
--------------------------------------------------------------------------------
--
-- The MIT License (MIT)
--
-- Copyright (c) 2016 Chris Hocking.
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------





--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   T H E    M A I N    S C R I P T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- BEGIN MODULE:
--------------------------------------------------------------------------------

local mod = {}

--------------------------------------------------------------------------------
-- STANDARD EXTENSIONS:
--------------------------------------------------------------------------------

local application								= require("hs.application")
local base64									= require("hs.base64")
local chooser									= require("hs.chooser")
local console									= require("hs.console")
local distributednotifications					= require("hs.distributednotifications")
local drawing 									= require("hs.drawing")
local eventtap									= require("hs.eventtap")
local fnutils 									= require("hs.fnutils")
local fs										= require("hs.fs")
local geometry									= require("hs.geometry")
local host										= require("hs.host")
local hotkey									= require("hs.hotkey")
local http										= require("hs.http")
local image										= require("hs.image")
local inspect									= require("hs.inspect")
local keycodes									= require("hs.keycodes")
local logger									= require("hs.logger")
local menubar									= require("hs.menubar")
local mouse										= require("hs.mouse")
local notify									= require("hs.notify")
local osascript									= require("hs.osascript")
local pasteboard								= require("hs.pasteboard")
local pathwatcher								= require("hs.pathwatcher")
local screen									= require("hs.screen")
local settings									= require("hs.settings")
local sharing									= require("hs.sharing")
local timer										= require("hs.timer")
local window									= require("hs.window")
local windowfilter								= require("hs.window.filter")

--------------------------------------------------------------------------------
-- EXTERNAL EXTENSIONS:
--------------------------------------------------------------------------------

local ax 										= require("hs._asm.axuielement")
local touchbar 									= require("hs._asm.touchbar")

local fcp										= require("hs.finalcutpro")
local plist										= require("hs.plist")

--------------------------------------------------------------------------------
-- MODULES:
--------------------------------------------------------------------------------

local dialog									= require("hs.fcpxhacks.modules.dialog")
local slaxdom 									= require("hs.fcpxhacks.modules.slaxml.slaxdom")
local slaxml									= require("hs.fcpxhacks.modules.slaxml")
local tools										= require("hs.fcpxhacks.modules.tools")
local just										= require("hs.just")

--------------------------------------------------------------------------------
-- PLUGINS:
--------------------------------------------------------------------------------

local clipboard									= require("hs.fcpxhacks.plugins.clipboard")
local hacksconsole								= require("hs.fcpxhacks.plugins.hacksconsole")
local hackshud									= require("hs.fcpxhacks.plugins.hackshud")
local voicecommands 							= require("hs.fcpxhacks.plugins.voicecommands")

local kc										= require("hs.fcpxhacks.plugins.shortcuts.keycodes")

--------------------------------------------------------------------------------
-- DEFAULT SETTINGS:
--------------------------------------------------------------------------------

local defaultSettings = {						["enableShortcutsDuringFullscreenPlayback"] 	= false,
												["scrollingTimelineActive"] 					= false,
												["enableHacksShortcutsInFinalCutPro"] 			= false,
												["enableVoiceCommands"]							= false,
												["chooserRememberLast"]							= true,
												["chooserShowAutomation"] 						= true,
												["chooserShowShortcuts"] 						= true,
												["chooserShowHacks"] 							= true,
												["chooserShowVideoEffects"] 					= true,
												["chooserShowAudioEffects"] 					= true,
												["chooserShowTransitions"] 						= true,
												["chooserShowTitles"] 							= true,
												["chooserShowGenerators"] 						= true,
												["chooserShowMenuItems"]						= true,
												["menubarShortcutsEnabled"] 					= true,
												["menubarAutomationEnabled"] 					= true,
												["menubarToolsEnabled"] 						= true,
												["menubarHacksEnabled"] 						= true,
												["enableCheckForUpdates"]						= true,
												["hudShowInspector"]							= true,
												["hudShowDropTargets"]							= true,
												["hudShowButtons"]								= true,
												["checkForUpdatesInterval"]						= 600,
												["highlightPlayheadTime"]						= 3}

--------------------------------------------------------------------------------
-- VARIABLES:
--------------------------------------------------------------------------------

local execute									= hs.execute									-- Execute!
local touchBarSupported					 		= touchbar.supported()							-- Touch Bar Supported?
local log										= logger.new("fcpx10-3")

mod.debugMode									= false											-- Debug Mode is off by default.
mod.scrollingTimelineSpacebarPressed			= false											-- Was spacebar pressed?
mod.scrollingTimelineWatcherWorking 			= false											-- Is Scrolling Timeline Spacebar Held Down?
mod.releaseColorBoardDown						= false											-- Color Board Shortcut Currently Being Pressed
mod.releaseMouseColorBoardDown 					= false											-- Color Board Mouse Shortcut Currently Being Pressed
mod.mouseInsideTouchbar							= false											-- Mouse Inside Touch Bar?
mod.shownUpdateNotification		 				= false											-- Shown Update Notification Already?

mod.touchBarWindow 								= nil			 								-- Touch Bar Window

mod.browserHighlight 							= nil											-- Used for Highlight Browser Playhead
mod.browserHighlightTimer 						= nil											-- Used for Highlight Browser Playhead
mod.browserHighlight							= nil											-- Scrolling Timeline Timer

mod.scrollingTimelineTimer						= nil											-- Scrolling Timeline Timer
mod.scrollingTimelineScrollbarTimer				= nil											-- Scrolling Timeline Scrollbar Timer

mod.finalCutProShortcutKey 						= nil											-- Table of all Final Cut Pro Shortcuts
mod.finalCutProShortcutKeyPlaceholders 			= nil											-- Table of all needed Final Cut Pro Shortcuts
mod.newDeviceMounted 							= nil											-- New Device Mounted Volume Watcher
mod.lastCommandSet								= nil											-- Last Keyboard Shortcut Command Set
mod.allowMovingMarkers							= nil											-- Used in refreshMenuBar
mod.FFPeriodicBackupInterval 					= nil											-- Used in refreshMenuBar
mod.FFSuspendBGOpsDuringPlay 					= nil											-- Used in refreshMenuBar
mod.FFEnableGuards								= nil											-- Used in refreshMenuBar
mod.FFAutoRenderDelay							= nil											-- Used in refreshMenuBar

mod.installedLanguages							= {}											-- Table of Installed Language Files

mod.hacksLoaded 								= false											-- Has FCPX Hacks Loaded Yet?

mod.isFinalCutProActive 						= false											-- Is Final Cut Pro Active? Used by Watchers.
mod.wasFinalCutProOpen							= false											-- Used by Assign Transitions/Effects/Titles/Generators Shortcut

--------------------------------------------------------------------------------
-- LOAD SCRIPT:
--------------------------------------------------------------------------------
function loadScript()

	--------------------------------------------------------------------------------
	-- Debug Mode:
	--------------------------------------------------------------------------------
	mod.debugMode = settings.get("fcpxHacks.debugMode") or false
	debugMessage("Debug Mode Activated.")

	--------------------------------------------------------------------------------
	-- Need Accessibility Activated:
	--------------------------------------------------------------------------------
	hs.accessibilityState(true)

	--------------------------------------------------------------------------------
	-- Limit Error Messages for a clean console:
	--------------------------------------------------------------------------------
	console.titleVisibility("hidden")
	hotkey.setLogLevel("warning")
	windowfilter.setLogLevel(0) -- The wfilter errors are too annoying.
	windowfilter.ignoreAlways['System Events'] = true

	--------------------------------------------------------------------------------
	-- Setup i18n Languages:
	--------------------------------------------------------------------------------
	local languagePath = "hs/fcpxhacks/languages/"
	for file in fs.dir(languagePath) do
		if file:sub(-4) == ".lua" then
			local languageFile = io.open(hs.configdir .. "/" .. languagePath .. file, "r")
			if languageFile ~= nil then
				local languageFileData = languageFile:read("*all")
				if string.find(languageFileData, "-- LANGUAGE: ") ~= nil then
					local fileLanguage = string.sub(languageFileData, string.find(languageFileData, "-- LANGUAGE: ") + 13, string.find(languageFileData, "\n") - 1)
					local languageID = string.sub(file, 1, -5)
					mod.installedLanguages[#mod.installedLanguages + 1] = { id = languageID, language = fileLanguage }
				end
				languageFile:close()
			end
		end
	end
	table.sort(mod.installedLanguages, function(a, b) return a.language < b.language end)

	--------------------------------------------------------------------------------
	-- First time running 10.3? If so, let's trash the settings incase there's
	-- compatibility issues with an older version of FCPX Hacks:
	--------------------------------------------------------------------------------
	if settings.get("fcpxHacks.firstTimeRunning103") == nil then

		writeToConsole("First time running Final Cut Pro 10.3. Trashing settings.")

		--------------------------------------------------------------------------------
		-- Trash all FCPX Hacks Settings:
		--------------------------------------------------------------------------------
		for i, v in ipairs(settings.getKeys()) do
			if (v:sub(1,10)) == "fcpxHacks." then
				settings.set(v, nil)
			end
		end

		settings.set("fcpxHacks.firstTimeRunning103", false)

	end

	--------------------------------------------------------------------------------
	-- Check for Final Cut Pro Updates:
	--------------------------------------------------------------------------------
	local lastFinalCutProVersion = settings.get("fcpxHacks.lastFinalCutProVersion")
	if lastFinalCutProVersion == nil then
		settings.set("fcpxHacks.lastFinalCutProVersion", fcp:getVersion())
	else
		if lastFinalCutProVersion ~= fcp:getVersion() then
			for i, v in ipairs(settings.getKeys()) do
				if (v:sub(1,10)) == "fcpxHacks." then
					if v:sub(-16) == "chooserMenuItems" then
						settings.set(v, nil)
					end
				end
			end
			settings.set("fcpxHacks.lastFinalCutProVersion", fcp:getVersion())
		end
	end

	--------------------------------------------------------------------------------
	-- Apply Default Settings:
	--------------------------------------------------------------------------------
	for k, v in pairs(defaultSettings) do
		if settings.get("fcpxHacks." .. k) == nil then
			settings.set("fcpxHacks." .. k, v)
		end
	end

	--------------------------------------------------------------------------------
	-- Check if we need to update the Final Cut Pro Shortcut Files:
	--------------------------------------------------------------------------------
	if settings.get("fcpxHacks.lastVersion") == nil then
		settings.set("fcpxHacks.lastVersion", fcpxhacks.scriptVersion)
		settings.set("fcpxHacks.enableHacksShortcutsInFinalCutPro", false)
	else
		if tonumber(settings.get("fcpxHacks.lastVersion")) < tonumber(fcpxhacks.scriptVersion) then
			if settings.get("fcpxHacks.enableHacksShortcutsInFinalCutPro") then
				local finalCutProRunning = fcp:isRunning()
				if finalCutProRunning then
					dialog.displayMessage(i18n("newKeyboardShortcuts"))
					updateKeyboardShortcuts()
					if not fcp:restart() then
						--------------------------------------------------------------------------------
						-- Failed to restart Final Cut Pro:
						--------------------------------------------------------------------------------
						dialog.displayErrorMessage(i18n("restartFinalCutProFailed"))
						return "Failed"
					end
				else
					dialog.displayMessage(i18n("newKeyboardShortcuts"))
					updateKeyboardShortcuts()
				end
			end
		end
		settings.set("fcpxHacks.lastVersion", fcpxhacks.scriptVersion)
	end

	--------------------------------------------------------------------------------
	-- Setup Touch Bar:
	--------------------------------------------------------------------------------
	if touchBarSupported then

		--------------------------------------------------------------------------------
		-- New Touch Bar:
		--------------------------------------------------------------------------------
		mod.touchBarWindow = touchbar.new()

		--------------------------------------------------------------------------------
		-- Touch Bar Watcher:
		--------------------------------------------------------------------------------
		mod.touchBarWindow:setCallback(touchbarWatcher)

		--------------------------------------------------------------------------------
		-- Get last Touch Bar Location from Settings:
		--------------------------------------------------------------------------------
		local lastTouchBarLocation = settings.get("fcpxHacks.lastTouchBarLocation")
		if lastTouchBarLocation ~= nil then	mod.touchBarWindow:topLeft(lastTouchBarLocation) end

		--------------------------------------------------------------------------------
		-- Draggable Touch Bar:
		--------------------------------------------------------------------------------
		local events = eventtap.event.types
		touchbarKeyboardWatcher = eventtap.new({events.flagsChanged, events.keyDown, events.leftMouseDown}, function(ev)
			if mod.mouseInsideTouchbar then
				if ev:getType() == events.flagsChanged and ev:getRawEventData().CGEventData.flags == 524576 then
					mod.touchBarWindow:backgroundColor{ red = 1 }
								  	:movable(true)
								  	:acceptsMouseEvents(false)
				elseif ev:getType() ~= events.leftMouseDown then
					mod.touchBarWindow:backgroundColor{ white = 0 }
								  :movable(false)
								  :acceptsMouseEvents(true)
					settings.set("fcpxHacks.lastTouchBarLocation", mod.touchBarWindow:topLeft())
				end
			end
			return false
		end):start()

	end

	--------------------------------------------------------------------------------
	-- Setup Watches:
	--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- Create and start the application event watcher:
		--------------------------------------------------------------------------------
		watcher = application.watcher.new(finalCutProWatcher):start()

		--------------------------------------------------------------------------------
		-- Watch For Hammerspoon Script Updates:
		--------------------------------------------------------------------------------
		hammerspoonWatcher = pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", hammerspoonConfigWatcher):start()

		--------------------------------------------------------------------------------
		-- Watch for Final Cut Pro plist Changes:
		--------------------------------------------------------------------------------
		preferencesWatcher = pathwatcher.new("~/Library/Preferences/", finalCutProSettingsWatcher):start()

		--------------------------------------------------------------------------------
		-- Watch for Shared Clipboard Changes:
		--------------------------------------------------------------------------------
		local sharedClipboardPath = settings.get("fcpxHacks.sharedClipboardPath")
		if sharedClipboardPath ~= nil then
			if tools.doesDirectoryExist(sharedClipboardPath) then
				sharedClipboardWatcher = pathwatcher.new(sharedClipboardPath, sharedClipboardFileWatcher):start()
			else
				writeToConsole("The Shared Clipboard Directory could not be found, so disabling.")
				settings.set("fcpxHacks.sharedClipboardPath", nil)
				settings.set("fcpxHacks.enableSharedClipboard", false)
			end
		end

		--------------------------------------------------------------------------------
		-- Watch for Shared XML Changes:
		--------------------------------------------------------------------------------
		local enableXMLSharing = settings.get("fcpxHacks.enableXMLSharing") or false
		if enableXMLSharing then
			local xmlSharingPath = settings.get("fcpxHacks.xmlSharingPath")
			if xmlSharingPath ~= nil then
				if tools.doesDirectoryExist(xmlSharingPath) then
					sharedXMLWatcher = pathwatcher.new(xmlSharingPath, sharedXMLFileWatcher):start()
				else
					writeToConsole("The Shared XML Folder(s) could not be found, so disabling.")
					settings.set("fcpxHacks.xmlSharingPath", nil)
					settings.set("fcpxHacks.enableXMLSharing", false)
				end
			end
		end

		--------------------------------------------------------------------------------
		-- Full Screen Keyboard Watcher:
		--------------------------------------------------------------------------------
		fullscreenKeyboardWatcher()

		--------------------------------------------------------------------------------
		-- Final Cut Pro Window Watcher:
		--------------------------------------------------------------------------------
		finalCutProWindowWatcher()

		--------------------------------------------------------------------------------
		-- Scrolling Timeline Watcher:
		--------------------------------------------------------------------------------
		scrollingTimelineWatcher()

		--------------------------------------------------------------------------------
		-- Clipboard Watcher:
		--------------------------------------------------------------------------------
		local enableClipboardHistory = settings.get("fcpxHacks.enableClipboardHistory") or false
		if enableClipboardHistory then clipboard.startWatching() end

		--------------------------------------------------------------------------------
		-- Notification Watcher:
		--------------------------------------------------------------------------------
		local enableMobileNotifications = settings.get("fcpxHacks.enableMobileNotifications") or false
		if enableMobileNotifications then notificationWatcher() end

		--------------------------------------------------------------------------------
		-- Media Import Watcher:
		--------------------------------------------------------------------------------
		local enableMediaImportWatcher = settings.get("fcpxHacks.enableMediaImportWatcher") or false
		if enableMediaImportWatcher then mediaImportWatcher() end

	--------------------------------------------------------------------------------
	-- Bind Keyboard Shortcuts:
	--------------------------------------------------------------------------------
	mod.lastCommandSet = fcp:getActiveCommandSetPath()
	bindKeyboardShortcuts()

	--------------------------------------------------------------------------------
	-- Load Hacks HUD:
	--------------------------------------------------------------------------------
	if settings.get("fcpxHacks.enableHacksHUD") then
		hackshud.new()
	end

	--------------------------------------------------------------------------------
	-- Activate the correct modal state:
	--------------------------------------------------------------------------------
	if fcp:isFrontmost() then

		--------------------------------------------------------------------------------
		-- Used by Watchers to prevent double-ups:
		--------------------------------------------------------------------------------
		mod.isFinalCutProActive = true

		--------------------------------------------------------------------------------
		-- Enable Final Cut Pro Shortcut Keys:
		--------------------------------------------------------------------------------
		hotkeys:enter()

		--------------------------------------------------------------------------------
		-- Enable Fullscreen Playback Shortcut Keys:
		--------------------------------------------------------------------------------
		if settings.get("fcpxHacks.enableShortcutsDuringFullscreenPlayback") then
			fullscreenKeyboardWatcherDown:start()
		end

		--------------------------------------------------------------------------------
		-- Enable Scrolling Timeline:
		--------------------------------------------------------------------------------
		if settings.get("fcpxHacks.scrollingTimelineActive") then
			mod.scrollingTimelineWatcherDown:start()
		end

		--------------------------------------------------------------------------------
		-- Show Hacks HUD:
		--------------------------------------------------------------------------------
		if settings.get("fcpxHacks.enableHacksHUD") then
			hackshud.show()
		end

		--------------------------------------------------------------------------------
		-- Enable Voice Commands:
		--------------------------------------------------------------------------------
		if settings.get("fcpxHacks.enableVoiceCommands") then
			voicecommands.start()
		end

	else

		--------------------------------------------------------------------------------
		-- Used by Watchers to prevent double-ups:
		--------------------------------------------------------------------------------
		mod.isFinalCutProActive = false

		--------------------------------------------------------------------------------
		-- Disable Final Cut Pro Shortcut Keys:
		--------------------------------------------------------------------------------
		hotkeys:exit()

		--------------------------------------------------------------------------------
		-- Disable Fullscreen Playback Shortcut Keys:
		--------------------------------------------------------------------------------
		if fullscreenKeyboardWatcherUp ~= nil then
			fullscreenKeyboardWatcherUp:stop()
			fullscreenKeyboardWatcherDown:stop()
		end

		--------------------------------------------------------------------------------
		-- Disable Scrolling Timeline:
		--------------------------------------------------------------------------------
		if mod.scrollingTimelineWatcherDown ~= nil then
			mod.scrollingTimelineWatcherDown:stop()
		end

	end

	-------------------------------------------------------------------------------
	-- Set up Menubar:
	--------------------------------------------------------------------------------
	fcpxMenubar = menubar.newWithPriority(1)

		--------------------------------------------------------------------------------
		-- Set Tool Tip:
		--------------------------------------------------------------------------------
		fcpxMenubar:setTooltip("FCPX Hacks " .. i18n("version") .. " " .. fcpxhacks.scriptVersion)

		--------------------------------------------------------------------------------
		-- Work out Menubar Display Mode:
		--------------------------------------------------------------------------------
		updateMenubarIcon()

		--------------------------------------------------------------------------------
		-- Populate the Menubar for the first time:
		--------------------------------------------------------------------------------
		refreshMenuBar(true)

	-------------------------------------------------------------------------------
	-- Set up Chooser:
	-------------------------------------------------------------------------------
	hacksconsole.new()

	--------------------------------------------------------------------------------
	-- All loaded!
	--------------------------------------------------------------------------------
	writeToConsole("Successfully loaded.")
	dialog.displayNotification("FCPX Hacks (v" .. fcpxhacks.scriptVersion .. ") " .. i18n("hasLoaded"))

	--------------------------------------------------------------------------------
	-- Check for Script Updates:
	--------------------------------------------------------------------------------
	local checkForUpdatesInterval = settings.get("fcpxHacks.checkForUpdatesInterval")
	checkForUpdatesTimer = timer.doEvery(checkForUpdatesInterval, checkForUpdates)
	checkForUpdatesTimer:fire()

	mod.hacksLoaded = true

end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------





--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   D E V E L O P M E N T      T O O L S                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- TESTING GROUND (CONTROL + OPTION + COMMAND + Q):
--------------------------------------------------------------------------------
function testingGround()

	--------------------------------------------------------------------------------
	-- Clear Console:
	--------------------------------------------------------------------------------
	console.clearConsole()

	local librarytools = require("hs.finalcutpro.librarytools")
	librarytools.test()

end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------





--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                    K E Y B O A R D     S H O R T C U T S                   --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- DEFAULT SHORTCUT KEYS:
--------------------------------------------------------------------------------
function defaultShortcutKeys()

	local control					= {"ctrl"}
	local controlShift 				= {"ctrl", "shift"}
	local controlOptionCommand 		= {"ctrl", "option", "command"}
	local controlOptionCommandShift = {"ctrl", "option", "command", "shift"}

    local defaultShortcutKeys = {
        FCPXHackLaunchFinalCutPro                                   = { characterString = kc.keyCodeTranslator("l"),            modifiers = controlOptionCommand,                   fn = function() fcp:launch() end,                                   releasedFn = nil,                                                       repeatFn = nil,         global = true },
        FCPXHackShowListOfShortcutKeys                              = { characterString = kc.keyCodeTranslator("f1"),           modifiers = controlOptionCommand,                   fn = function() displayShortcutList() end,                          releasedFn = nil,                                                       repeatFn = nil,         global = true },

        FCPXHackHighlightBrowserPlayhead                            = { characterString = kc.keyCodeTranslator("h"),            modifiers = controlOptionCommand,                   fn = function() highlightFCPXBrowserPlayhead() end,                 releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackRevealInBrowserAndHighlight                         = { characterString = kc.keyCodeTranslator("f"),            modifiers = controlOptionCommand,                   fn = function() matchFrameThenHighlightFCPXBrowserPlayhead() end,   releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSingleMatchFrameAndHighlight                        = { characterString = kc.keyCodeTranslator("s"),            modifiers = controlOptionCommand,                   fn = function() singleMatchFrame() end,                             releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackRevealMulticamClipInBrowserAndHighlight             = { characterString = kc.keyCodeTranslator("d"),            modifiers = controlOptionCommand,                   fn = function() multicamMatchFrame(true) end,                       releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackRevealMulticamClipInAngleEditorAndHighlight         = { characterString = kc.keyCodeTranslator("g"),            modifiers = controlOptionCommand,                   fn = function() multicamMatchFrame(false) end,                      releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackBatchExportFromBrowser                              = { characterString = kc.keyCodeTranslator("e"),            modifiers = controlOptionCommand,                   fn = function() batchExport() end,                                  releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackChangeBackupInterval                                = { characterString = kc.keyCodeTranslator("b"),            modifiers = controlOptionCommand,                   fn = function() changeBackupInterval() end,                         releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackToggleTimecodeOverlays                              = { characterString = kc.keyCodeTranslator("t"),            modifiers = controlOptionCommand,                   fn = function() toggleTimecodeOverlay() end,                        releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackToggleMovingMarkers                                 = { characterString = kc.keyCodeTranslator("y"),            modifiers = controlOptionCommand,                   fn = function() toggleMovingMarkers() end,                          releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackAllowTasksDuringPlayback                            = { characterString = kc.keyCodeTranslator("p"),            modifiers = controlOptionCommand,                   fn = function() togglePerformTasksDuringPlayback() end,             releasedFn = nil,                                                       repeatFn = nil },

        FCPXHackSelectColorBoardPuckOne                             = { characterString = kc.keyCodeTranslator("m"),            modifiers = controlOptionCommand,                   fn = function() colorBoardSelectPuck("*", "global") end,            releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSelectColorBoardPuckTwo                             = { characterString = kc.keyCodeTranslator(","),            modifiers = controlOptionCommand,                   fn = function() colorBoardSelectPuck("*", "shadows") end,           releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSelectColorBoardPuckThree                           = { characterString = kc.keyCodeTranslator("."),            modifiers = controlOptionCommand,                   fn = function() colorBoardSelectPuck("*", "midtones") end,          releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSelectColorBoardPuckFour                            = { characterString = kc.keyCodeTranslator("/"),            modifiers = controlOptionCommand,                   fn = function() colorBoardSelectPuck("*", "highlights") end,        releasedFn = nil,                                                       repeatFn = nil },

        FCPXHackRestoreKeywordPresetOne                             = { characterString = kc.keyCodeTranslator("1"),            modifiers = controlOptionCommand,                   fn = function() restoreKeywordSearches(1) end,                      releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackRestoreKeywordPresetTwo                             = { characterString = kc.keyCodeTranslator("2"),            modifiers = controlOptionCommand,                   fn = function() restoreKeywordSearches(2) end,                      releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackRestoreKeywordPresetThree                           = { characterString = kc.keyCodeTranslator("3"),            modifiers = controlOptionCommand,                   fn = function() restoreKeywordSearches(3) end,                      releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackRestoreKeywordPresetFour                            = { characterString = kc.keyCodeTranslator("4"),            modifiers = controlOptionCommand,                   fn = function() restoreKeywordSearches(4) end,                      releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackRestoreKeywordPresetFive                            = { characterString = kc.keyCodeTranslator("5"),            modifiers = controlOptionCommand,                   fn = function() restoreKeywordSearches(5) end,                      releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackRestoreKeywordPresetSix                             = { characterString = kc.keyCodeTranslator("6"),            modifiers = controlOptionCommand,                   fn = function() restoreKeywordSearches(6) end,                      releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackRestoreKeywordPresetSeven                           = { characterString = kc.keyCodeTranslator("7"),            modifiers = controlOptionCommand,                   fn = function() restoreKeywordSearches(7) end,                      releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackRestoreKeywordPresetEight                           = { characterString = kc.keyCodeTranslator("8"),            modifiers = controlOptionCommand,                   fn = function() restoreKeywordSearches(8) end,                      releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackRestoreKeywordPresetNine                            = { characterString = kc.keyCodeTranslator("9"),            modifiers = controlOptionCommand,                   fn = function() restoreKeywordSearches(9) end,                      releasedFn = nil,                                                       repeatFn = nil },

        FCPXHackHUD                                                 = { characterString = kc.keyCodeTranslator("a"),            modifiers = controlOptionCommand,                   fn = function() toggleEnableHacksHUD() end,                         releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackToggleTouchBar                                      = { characterString = kc.keyCodeTranslator("z"),            modifiers = controlOptionCommand,                   fn = function() toggleTouchBar() end,                               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackScrollingTimeline                                   = { characterString = kc.keyCodeTranslator("w"),            modifiers = controlOptionCommand,                   fn = function() toggleScrollingTimeline() end,                      releasedFn = nil,                                                       repeatFn = nil },

        FCPXHackChangeTimelineClipHeightUp                          = { characterString = kc.keyCodeTranslator("+"),            modifiers = controlOptionCommand,                   fn = function() changeTimelineClipHeight("up") end,                 releasedFn = function() changeTimelineClipHeightRelease() end,          repeatFn = nil },
        FCPXHackChangeTimelineClipHeightDown                        = { characterString = kc.keyCodeTranslator("-"),            modifiers = controlOptionCommand,                   fn = function() changeTimelineClipHeight("down") end,               releasedFn = function() changeTimelineClipHeightRelease() end,          repeatFn = nil },

        FCPXHackSelectForward                                       = { characterString = kc.keyCodeTranslator("right"),        modifiers = controlOptionCommand,                   fn = function() selectAllTimelineClips(true) end,                   releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSelectBackwards                                     = { characterString = kc.keyCodeTranslator("left"),         modifiers = controlOptionCommand,                   fn = function() selectAllTimelineClips(false) end,                  releasedFn = nil,                                                       repeatFn = nil },

        FCPXHackSaveKeywordPresetOne                                = { characterString = kc.keyCodeTranslator("1"),            modifiers = controlOptionCommandShift,              fn = function() saveKeywordSearches(1) end,                         releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSaveKeywordPresetTwo                                = { characterString = kc.keyCodeTranslator("2"),            modifiers = controlOptionCommandShift,              fn = function() saveKeywordSearches(2) end,                         releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSaveKeywordPresetThree                              = { characterString = kc.keyCodeTranslator("3"),            modifiers = controlOptionCommandShift,              fn = function() saveKeywordSearches(3) end,                         releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSaveKeywordPresetFour                               = { characterString = kc.keyCodeTranslator("4"),            modifiers = controlOptionCommandShift,              fn = function() saveKeywordSearches(4) end,                         releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSaveKeywordPresetFive                               = { characterString = kc.keyCodeTranslator("5"),            modifiers = controlOptionCommandShift,              fn = function() saveKeywordSearches(5) end,                         releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSaveKeywordPresetSix                                = { characterString = kc.keyCodeTranslator("6"),            modifiers = controlOptionCommandShift,              fn = function() saveKeywordSearches(6) end,                         releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSaveKeywordPresetSeven                              = { characterString = kc.keyCodeTranslator("7"),            modifiers = controlOptionCommandShift,              fn = function() saveKeywordSearches(7) end,                         releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSaveKeywordPresetEight                              = { characterString = kc.keyCodeTranslator("8"),            modifiers = controlOptionCommandShift,              fn = function() saveKeywordSearches(8) end,                         releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSaveKeywordPresetNine                               = { characterString = kc.keyCodeTranslator("9"),            modifiers = controlOptionCommandShift,              fn = function() saveKeywordSearches(9) end,                         releasedFn = nil,                                                       repeatFn = nil },

        FCPXHackEffectsOne                                          = { characterString = kc.keyCodeTranslator("1"),            modifiers = controlShift,                           fn = function() effectsShortcut(1) end,                             releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackEffectsTwo                                          = { characterString = kc.keyCodeTranslator("2"),            modifiers = controlShift,                           fn = function() effectsShortcut(2) end,                             releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackEffectsThree                                        = { characterString = kc.keyCodeTranslator("3"),            modifiers = controlShift,                           fn = function() effectsShortcut(3) end,                             releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackEffectsFour                                         = { characterString = kc.keyCodeTranslator("4"),            modifiers = controlShift,                           fn = function() effectsShortcut(4) end,                             releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackEffectsFive                                         = { characterString = kc.keyCodeTranslator("5"),            modifiers = controlShift,                           fn = function() effectsShortcut(5) end,                             releasedFn = nil,                                                       repeatFn = nil },

        FCPXHackConsole                                             = { characterString = kc.keyCodeTranslator("space"),        modifiers = control,                                fn = function() hacksconsole.show(); mod.scrollingTimelineWatcherWorking = false end, releasedFn = nil,                                     repeatFn = nil },

        FCPXHackMoveToPlayhead                                      = { characterString = "",                                   modifiers = {},                                     fn = function() moveToPlayhead() end,                               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackLockPlayhead                                        = { characterString = "",                                   modifiers = {},                                     fn = function() toggleLockPlayhead() end,                           releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackToggleVoiceCommands                                 = { characterString = "",                                   modifiers = {},                                     fn = function() toggleEnableVoiceCommands() end,                    releasedFn = nil,                                                       repeatFn = nil },

        FCPXHackTransitionsOne                                      = { characterString = "",                                   modifiers = {},                                     fn = function() transitionsShortcut(1) end,                         releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackTransitionsTwo                                      = { characterString = "",                                   modifiers = {},                                     fn = function() transitionsShortcut(2) end,                         releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackTransitionsThree                                    = { characterString = "",                                   modifiers = {},                                     fn = function() transitionsShortcut(3) end,                         releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackTransitionsFour                                     = { characterString = "",                                   modifiers = {},                                     fn = function() transitionsShortcut(4) end,                         releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackTransitionsFive                                     = { characterString = "",                                   modifiers = {},                                     fn = function() transitionsShortcut(5) end,                         releasedFn = nil,                                                       repeatFn = nil },

        FCPXHackTitlesOne                                           = { characterString = "",                                   modifiers = {},                                     fn = function() titlesShortcut(1) end,                              releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackTitlesTwo                                           = { characterString = "",                                   modifiers = {},                                     fn = function() titlesShortcut(2) end,                              releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackTitlesThree                                         = { characterString = "",                                   modifiers = {},                                     fn = function() titlesShortcut(3) end,                              releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackTitlesFour                                          = { characterString = "",                                   modifiers = {},                                     fn = function() titlesShortcut(4) end,                              releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackTitlesFive                                          = { characterString = "",                                   modifiers = {},                                     fn = function() titlesShortcut(5) end,                              releasedFn = nil,                                                       repeatFn = nil },

        FCPXHackGeneratorsOne                                       = { characterString = "",                                   modifiers = {},                                     fn = function() generatorsShortcut(1) end,                          releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackGeneratorsTwo                                       = { characterString = "",                                   modifiers = {},                                     fn = function() generatorsShortcut(2) end,                          releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackGeneratorsThree                                     = { characterString = "",                                   modifiers = {},                                     fn = function() generatorsShortcut(3) end,                          releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackGeneratorsFour                                      = { characterString = "",                                   modifiers = {},                                     fn = function() generatorsShortcut(4) end,                          releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackGeneratorsFive                                      = { characterString = "",                                   modifiers = {},                                     fn = function() generatorsShortcut(5) end,                          releasedFn = nil,                                                       repeatFn = nil },

        FCPXHackColorPuckOne                                        = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "global") end,                    releasedFn = nil,                                           repeatFn = nil },
        FCPXHackColorPuckTwo                                        = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "shadows") end,                   releasedFn = nil,                                           repeatFn = nil },
        FCPXHackColorPuckThree                                      = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "midtones") end,                  releasedFn = nil,                                           repeatFn = nil },
        FCPXHackColorPuckFour                                       = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "highlights") end,                releasedFn = nil,                                           repeatFn = nil },

        FCPXHackSaturationPuckOne                                   = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("saturation", "global") end,               releasedFn = nil,                                           repeatFn = nil },
        FCPXHackSaturationPuckTwo                                   = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("saturation", "shadows") end,              releasedFn = nil,                                           repeatFn = nil },
        FCPXHackSaturationPuckThree                                 = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("saturation", "midtones") end,             releasedFn = nil,                                           repeatFn = nil },
        FCPXHackSaturationPuckFour                                  = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("saturation", "highlights") end,           releasedFn = nil,                                           repeatFn = nil },

        FCPXHackExposurePuckOne                                     = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("exposure", "global") end,                 releasedFn = nil,                                           repeatFn = nil },
        FCPXHackExposurePuckTwo                                     = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("exposure", "shadows") end,                releasedFn = nil,                                           repeatFn = nil },
        FCPXHackExposurePuckThree                                   = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("exposure", "midtones") end,               releasedFn = nil,                                           repeatFn = nil },
        FCPXHackExposurePuckFour                                    = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("exposure", "highlights") end,             releasedFn = nil,                                           repeatFn = nil },

        FCPXHackColorPuckOneUp                                      = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "global", "up") end,              releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackColorPuckTwoUp                                      = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "shadows", "up") end,             releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackColorPuckThreeUp                                    = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "midtones", "up") end,            releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackColorPuckFourUp                                     = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "highlights", "up") end,          releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },

        FCPXHackColorPuckOneDown                                    = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "global", "down") end,            releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackColorPuckTwoDown                                    = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "shadows", "down") end,           releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackColorPuckThreeDown                                  = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "midtones", "down") end,          releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackColorPuckFourDown                                   = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "highlights", "down") end,        releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },

        FCPXHackColorPuckOneLeft                                    = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "global", "left") end,            releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackColorPuckTwoLeft                                    = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "global", "left") end,            releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackColorPuckThreeLeft                                  = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "global", "left") end,            releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackColorPuckFourLeft                                   = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "global", "left") end,            releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },

        FCPXHackColorPuckOneRight                                   = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "global", "right") end,           releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackColorPuckTwoRight                                   = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "shadows", "right") end,          releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackColorPuckThreeRight                                 = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "midtones", "right") end,         releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackColorPuckFourRight                                  = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "highlights", "right") end,       releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },

        FCPXHackSaturationPuckOneUp                                 = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("saturation", "global", "up") end,         releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackSaturationPuckTwoUp                                 = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("saturation", "shadows", "up") end,        releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackSaturationPuckThreeUp                               = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("saturation", "midtones", "up") end,       releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackSaturationPuckFourUp                                = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("saturation", "highlights", "up") end,     releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },

        FCPXHackSaturationPuckOneDown                               = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("saturation", "global", "down") end,       releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackSaturationPuckTwoDown                               = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("saturation", "shadows", "down") end,      releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackSaturationPuckThreeDown                             = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("saturation", "midtones", "down") end,     releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackSaturationPuckFourDown                              = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("saturation", "highlights", "down") end,   releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },

        FCPXHackExposurePuckOneUp                                   = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("exposure", "global", "up") end,           releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackExposurePuckTwoUp                                   = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("exposure", "shadows", "up") end,          releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackExposurePuckThreeUp                                 = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("exposure", "midtones", "up") end,         releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackExposurePuckFourUp                                  = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("exposure", "highlights", "up") end,       releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },

        FCPXHackExposurePuckOneDown                                 = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("exposure", "global", "down") end,         releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackExposurePuckTwoDown                                 = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("exposure", "shadows", "down") end,        releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackExposurePuckThreeDown                               = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("exposure", "midtones", "down") end,       releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackExposurePuckFourDown                                = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("exposure", "highlights", "down") end,     releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },

        FCPXHackCreateOptimizedMediaOn                              = { characterString = "",                                   modifiers = {},                                     fn = function() toggleCreateOptimizedMedia(true) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCreateOptimizedMediaOff                             = { characterString = "",                                   modifiers = {},                                     fn = function() toggleCreateOptimizedMedia(false) end,              releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCreateMulticamOptimizedMediaOn                      = { characterString = "",                                   modifiers = {},                                     fn = function() toggleCreateMulticamOptimizedMedia(true) end,       releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCreateMulticamOptimizedMediaOff                     = { characterString = "",                                   modifiers = {},                                     fn = function() toggleCreateMulticamOptimizedMedia(false) end,      releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCreateProxyMediaOn                                  = { characterString = "",                                   modifiers = {},                                     fn = function() toggleCreateProxyMedia(true) end,                   releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCreateProxyMediaOff                                 = { characterString = "",                                   modifiers = {},                                     fn = function() toggleCreateProxyMedia(false) end,                  releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackLeaveInPlaceOn                                      = { characterString = "",                                   modifiers = {},                                     fn = function() toggleLeaveInPlace(true) end,                       releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackLeaveInPlaceOff                                     = { characterString = "",                                   modifiers = {},                                     fn = function() toggleLeaveInPlace(false) end,                      releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackBackgroundRenderOn                                  = { characterString = "",                                   modifiers = {},                                     fn = function() toggleBackgroundRender(true) end,                   releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackBackgroundRenderOff                                 = { characterString = "",                                   modifiers = {},                                     fn = function() toggleBackgroundRender(false) end,                  releasedFn = nil,                                                       repeatFn = nil },

        FCPXHackChangeSmartCollectionsLabel                         = { characterString = "",                                   modifiers = {},                                     fn = function() changeSmartCollectionsLabel() end,                  releasedFn = nil,                                                       repeatFn = nil },

        FCPXHackSelectClipAtLaneOne                                 = { characterString = "",                                   modifiers = {},                                     fn = function() selectClipAtLane(1) end,                            releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSelectClipAtLaneTwo                                 = { characterString = "",                                   modifiers = {},                                     fn = function() selectClipAtLane(2) end,                            releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSelectClipAtLaneThree                               = { characterString = "",                                   modifiers = {},                                     fn = function() selectClipAtLane(3) end,                            releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSelectClipAtLaneFour                                = { characterString = "",                                   modifiers = {},                                     fn = function() selectClipAtLane(4) end,                            releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSelectClipAtLaneFive                                = { characterString = "",                                   modifiers = {},                                     fn = function() selectClipAtLane(5) end,                            releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSelectClipAtLaneSix                                 = { characterString = "",                                   modifiers = {},                                     fn = function() selectClipAtLane(6) end,                            releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSelectClipAtLaneSeven                               = { characterString = "",                                   modifiers = {},                                     fn = function() selectClipAtLane(7) end,                            releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSelectClipAtLaneEight                               = { characterString = "",                                   modifiers = {},                                     fn = function() selectClipAtLane(8) end,                            releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSelectClipAtLaneNine                                = { characterString = "",                                   modifiers = {},                                     fn = function() selectClipAtLane(9) end,                            releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSelectClipAtLaneTen                                 = { characterString = "",                                   modifiers = {},                                     fn = function() selectClipAtLane(10) end,                           releasedFn = nil,                                                       repeatFn = nil },

        FCPXHackPuckOneMouse                                        = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("*", "global") end,             releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },
        FCPXHackPuckTwoMouse                                        = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("*", "shadows") end,            releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },
        FCPXHackPuckThreeMouse                                      = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("*", "midtones") end,           releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },
        FCPXHackPuckFourMouse                                       = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("*", "highlights") end,         releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },

        FCPXHackColorPuckOneMouse                                   = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("color", "global") end,         releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },
        FCPXHackColorPuckTwoMouse                                   = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("color", "shadows") end,        releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },
        FCPXHackColorPuckThreeMouse                                 = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("color", "midtones") end,       releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },
        FCPXHackColorPuckFourMouse                                  = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("color", "highlights") end,     releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },

        FCPXHackSaturationPuckOneMouse                              = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("saturation", "global") end,    releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },
        FCPXHackSaturationPuckTwoMouse                              = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("saturation", "shadows") end,   releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },
        FCPXHackSaturationPuckThreeMouse                            = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("saturation", "midtones") end,  releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },
        FCPXHackSaturationPuckFourMouse                             = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("saturation", "highlights") end,releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },

        FCPXHackExposurePuckOneMouse                                = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("exposure", "global") end,      releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },
        FCPXHackExposurePuckTwoMouse                                = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("exposure", "shadows") end,     releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },
        FCPXHackExposurePuckThreeMouse                              = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("exposure", "midtones") end,    releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },
        FCPXHackExposurePuckFourMouse                               = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("exposure", "highlights") end,  releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },

        FCPXHackCutSwitchAngle01Video                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Video", 1) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle02Video                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Video", 2) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle03Video                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Video", 3) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle04Video                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Video", 4) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle05Video                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Video", 5) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle06Video                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Video", 6) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle07Video                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Video", 7) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle08Video                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Video", 8) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle09Video                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Video", 9) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle10Video                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Video", 10) end,              releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle11Video                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Video", 11) end,              releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle12Video                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Video", 12) end,              releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle13Video                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Video", 13) end,              releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle14Video                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Video", 14) end,              releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle15Video                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Video", 15) end,              releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle16Video                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Video", 16) end,              releasedFn = nil,                                                       repeatFn = nil },

        FCPXHackCutSwitchAngle01Audio                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Audio", 1) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle02Audio                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Audio", 2) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle03Audio                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Audio", 3) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle04Audio                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Audio", 4) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle05Audio                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Audio", 5) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle06Audio                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Audio", 6) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle07Audio                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Audio", 7) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle08Audio                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Audio", 8) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle09Audio                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Audio", 9) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle10Audio                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Audio", 10) end,              releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle11Audio                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Audio", 11) end,              releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle12Audio                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Audio", 12) end,              releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle13Audio                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Audio", 13) end,              releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle14Audio                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Audio", 14) end,              releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle15Audio                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Audio", 15) end,              releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle16Audio                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Audio", 16) end,              releasedFn = nil,                                                       repeatFn = nil },

        FCPXHackCutSwitchAngle01Both                                = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Both", 1) end,                releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle02Both                                = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Both", 2) end,                releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle03Both                                = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Both", 3) end,                releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle04Both                                = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Both", 4) end,                releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle05Both                                = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Both", 5) end,                releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle06Both                                = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Both", 6) end,                releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle07Both                                = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Both", 7) end,                releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle08Both                                = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Both", 8) end,                releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle09Both                                = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Both", 9) end,                releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle10Both                                = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Both", 10) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle11Both                                = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Both", 11) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle12Both                                = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Both", 12) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle13Both                                = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Both", 13) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle14Both                                = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Both", 14) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle15Both                                = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Both", 15) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle16Both                                = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Both", 16) end,               releasedFn = nil,                                                       repeatFn = nil },
    }
	return defaultShortcutKeys
end

--------------------------------------------------------------------------------
-- BIND KEYBOARD SHORTCUTS:
--------------------------------------------------------------------------------
function bindKeyboardShortcuts()

	--------------------------------------------------------------------------------
	-- Get Enable Hacks Shortcuts in Final Cut Pro from Settings:
	--------------------------------------------------------------------------------
	local enableHacksShortcutsInFinalCutPro = settings.get("fcpxHacks.enableHacksShortcutsInFinalCutPro")
	if enableHacksShortcutsInFinalCutPro == nil then enableHacksShortcutsInFinalCutPro = false end

	--------------------------------------------------------------------------------
	-- Hacks Shortcuts Enabled:
	--------------------------------------------------------------------------------
	if enableHacksShortcutsInFinalCutPro then

		--------------------------------------------------------------------------------
		-- Get Shortcut Keys from plist:
		--------------------------------------------------------------------------------
		mod.finalCutProShortcutKey = nil
		mod.finalCutProShortcutKey = {}
		mod.finalCutProShortcutKeyPlaceholders = nil
		mod.finalCutProShortcutKeyPlaceholders = defaultShortcutKeys()

		--------------------------------------------------------------------------------
		-- Remove the default shortcut keys:
		--------------------------------------------------------------------------------
		for k, v in pairs(mod.finalCutProShortcutKeyPlaceholders) do
			mod.finalCutProShortcutKeyPlaceholders[k]["characterString"] = ""
			mod.finalCutProShortcutKeyPlaceholders[k]["modifiers"] = {}
		end

		--------------------------------------------------------------------------------
		-- If something goes wrong:
		--------------------------------------------------------------------------------
		if getShortcutsFromActiveCommandSet() ~= true then
			dialog.displayErrorMessage(i18n("customKeyboardShortcutsFailed"))
			enableHacksShortcutsInFinalCutPro = false
		end

	end

	--------------------------------------------------------------------------------
	-- Hacks Shortcuts Disabled:
	--------------------------------------------------------------------------------
	if not enableHacksShortcutsInFinalCutPro then

		--------------------------------------------------------------------------------
		-- Update Active Command Set:
		--------------------------------------------------------------------------------
		fcp:getActiveCommandSet(nil, true)

		--------------------------------------------------------------------------------
		-- Use Default Shortcuts Keys:
		--------------------------------------------------------------------------------
		mod.finalCutProShortcutKey = nil
		mod.finalCutProShortcutKey = defaultShortcutKeys()

	end

	--------------------------------------------------------------------------------
	-- Reset Modal Hotkey for Final Cut Pro Commands:
	--------------------------------------------------------------------------------
	hotkeys = nil

	--------------------------------------------------------------------------------
	-- Reset Global Hotkeys:
	--------------------------------------------------------------------------------
	local currentHotkeys = hotkey.getHotkeys()
	for i=1, #currentHotkeys do
		result = currentHotkeys[i]:delete()
	end

	--------------------------------------------------------------------------------
	-- Create a modal hotkey object with an absurd triggering hotkey:
	--------------------------------------------------------------------------------
	hotkeys = hotkey.modal.new({"command", "shift", "alt", "control"}, "F19")

	--------------------------------------------------------------------------------
	-- Enable Hotkeys Loop:
	--------------------------------------------------------------------------------
	for k, v in pairs(mod.finalCutProShortcutKey) do
		if v['characterString'] ~= "" and v['fn'] ~= nil then
			if v['global'] == true then
				--------------------------------------------------------------------------------
				-- Global Shortcut:
				--------------------------------------------------------------------------------
				hotkey.bind(v['modifiers'], v['characterString'], v['fn'], v['releasedFn'], v['repeatFn'])
			else
				--------------------------------------------------------------------------------
				-- Final Cut Pro Specific Shortcut:
				--------------------------------------------------------------------------------
				hotkeys:bind(v['modifiers'], v['characterString'], v['fn'], v['releasedFn'], v['repeatFn'])
			end
		end
	end

	--------------------------------------------------------------------------------
	-- Development Shortcut:
	--------------------------------------------------------------------------------
	if mod.debugMode then
		hotkey.bind({"ctrl", "option", "command"}, "q", function() testingGround() end)
	end

	--------------------------------------------------------------------------------
	-- Enable Hotkeys:
	--------------------------------------------------------------------------------
	hotkeys:enter()

	--------------------------------------------------------------------------------
	-- Let user know that keyboard shortcuts have loaded:
	--------------------------------------------------------------------------------
	dialog.displayNotification(i18n("keyboardShortcutsUpdated"))

end

--------------------------------------------------------------------------------
-- READ SHORTCUT KEYS FROM FINAL CUT PRO PLIST:
--------------------------------------------------------------------------------
function getShortcutsFromActiveCommandSet()

	local activeCommandSetTable = fcp:getActiveCommandSet(nil, true)

	if activeCommandSetTable ~= nil then
		for k, v in pairs(mod.finalCutProShortcutKeyPlaceholders) do

			if activeCommandSetTable[k] ~= nil then

				--------------------------------------------------------------------------------
				-- Multiple keyboard shortcuts for single function:
				--------------------------------------------------------------------------------
				if type(activeCommandSetTable[k][1]) == "table" then
					for x=1, #activeCommandSetTable[k] do

						local tempModifiers = nil
						local tempCharacterString = nil
						local keypadModifier = false

						if activeCommandSetTable[k][x]["modifiers"] ~= nil then
							if string.find(activeCommandSetTable[k][x]["modifiers"], "keypad") then keypadModifier = true end
							tempModifiers = kc.translateKeyboardModifiers(activeCommandSetTable[k][x]["modifiers"])
						else
							if activeCommandSetTable[k][x]["modifierMask"] ~= nil then
								tempModifiers = kc.translateModifierMask(activeCommandSetTable[k][x]["modifierMask"])
							end
						end

						if activeCommandSetTable[k][x]["characterString"] ~= nil then
							tempCharacterString = kc.translateKeyboardCharacters(activeCommandSetTable[k][x]["characterString"])
						else
							if activeCommandSetTable[k][x]["character"] ~= nil then
								if keypadModifier then
									tempCharacterString = kc.translateKeyboardKeypadCharacters(activeCommandSetTable[k][x]["character"])
								else
									tempCharacterString = kc.translateKeyboardCharacters(activeCommandSetTable[k][x]["character"])
								end
							end
						end

						local tempGlobalShortcut = mod.finalCutProShortcutKeyPlaceholders[k]['global'] or false

						local xValue = ""
						if x ~= 1 then xValue = tostring(x) end

						mod.finalCutProShortcutKey[k .. xValue] = {
							characterString 	= 		tempCharacterString,
							modifiers 			= 		tempModifiers,
							fn 					= 		mod.finalCutProShortcutKeyPlaceholders[k]['fn'],
							releasedFn 			= 		mod.finalCutProShortcutKeyPlaceholders[k]['releasedFn'],
							repeatFn 			= 		mod.finalCutProShortcutKeyPlaceholders[k]['repeatFn'],
							global 				= 		tempGlobalShortcut,
						}

					end
				--------------------------------------------------------------------------------
				-- Single keyboard shortcut for a single function:
				--------------------------------------------------------------------------------
				else

					local tempModifiers = nil
					local tempCharacterString = nil
					local keypadModifier = false

					if activeCommandSetTable[k]["modifiers"] ~= nil then
						tempModifiers = kc.translateKeyboardModifiers(activeCommandSetTable[k]["modifiers"])
					else
						if activeCommandSetTable[k]["modifierMask"] ~= nil then
							tempModifiers = kc.translateModifierMask(activeCommandSetTable[k]["modifierMask"])
						end
					end

					if activeCommandSetTable[k]["characterString"] ~= nil then
						tempCharacterString = kc.translateKeyboardCharacters(activeCommandSetTable[k]["characterString"])
					else
						if activeCommandSetTable[k]["character"] ~= nil then
							if keypadModifier then
								tempCharacterString = kc.translateKeyboardKeypadCharacters(activeCommandSetTable[k]["character"])
							else
								tempCharacterString = kc.translateKeyboardCharacters(activeCommandSetTable[k]["character"])
							end
						end
					end

					local tempGlobalShortcut = mod.finalCutProShortcutKeyPlaceholders[k]['global'] or false

					mod.finalCutProShortcutKey[k] = {
						characterString 	= 		tempCharacterString,
						modifiers 			= 		tempModifiers,
						fn 					= 		mod.finalCutProShortcutKeyPlaceholders[k]['fn'],
						releasedFn 			= 		mod.finalCutProShortcutKeyPlaceholders[k]['releasedFn'],
						repeatFn 			= 		mod.finalCutProShortcutKeyPlaceholders[k]['repeatFn'],
						global 				= 		tempGlobalShortcut,
					}

				end
			end
		end
		return true
	else
		return false
	end

end

--------------------------------------------------------------------------------
-- UPDATE KEYBOARD SHORTCUTS:
--------------------------------------------------------------------------------
function updateKeyboardShortcuts()

	--------------------------------------------------------------------------------
	-- Update Keyboard Settings:
	--------------------------------------------------------------------------------
	local result = enableHacksShortcuts()
	if result ~= "Done" then
		dialog.displayErrorMessage(i18n("failedToWriteToFile") .. "\n\n" .. result)
		settings.set("fcpxHacks.enableHacksShortcutsInFinalCutPro", false)
		return false
	end

	--------------------------------------------------------------------------------
	-- Revert back to default keyboard layout:
	--------------------------------------------------------------------------------
	local result = fcp:setPreference("Active Command Set", fcp:getPath() .. "/Contents/Resources/" .. fcp:getCurrentLanguage() .. ".lproj/Default.commandset")
	if not result then
		dialog.displayErrorMessage(i18n("activeCommandSetResetError"))
		return false
	end

end

--------------------------------------------------------------------------------
-- ENABLE HACKS SHORTCUTS:
--------------------------------------------------------------------------------
function enableHacksShortcuts()
	local appleScript = [[
		set finalCutProPath to "]] .. fcp:getPath() .. [["
		set finalCutProLanguages to ]] .. inspect(fcp:getSupportedLanguages()) .. [[

		--------------------------------------------------------------------------------
		-- Replace Files:
		--------------------------------------------------------------------------------
		try
			do shell script "cp -f ~/.hammerspoon/hs/fcpxhacks/plist/10-3/new/NSProCommandGroups.plist '" & finalCutProPath & "/Contents/Resources/NSProCommandGroups.plist'" with administrator privileges
			on error
				return "NSProCommandGroups.plist"
		end try
		try
			do shell script "cp -f ~/.hammerspoon/hs/fcpxhacks/plist/10-3/new/NSProCommands.plist '" & finalCutProPath & "/Contents/Resources/NSProCommands.plist'" with administrator privileges
			on error
				return "NSProCommands.plist"
		end try
		repeat with whichLanguage in finalCutProLanguages
			try
				do shell script "cp -f ~/.hammerspoon/hs/fcpxhacks/plist/10-3/new/" & whichLanguage & ".lproj/Default.commandset '" & finalCutProPath & "/Contents/Resources/" & whichLanguage & ".lproj/Default.commandset'" with administrator privileges
				on error
					return whichLanguage & ".lproj/Default.commandset"
			end try
			try
				do shell script "cp -f ~/.hammerspoon/hs/fcpxhacks/plist/10-3/new/" & whichLanguage & ".lproj/NSProCommandDescriptions.strings '" & finalCutProPath & "/Contents/Resources/" & whichLanguage & ".lproj/NSProCommandDescriptions.strings'" with administrator privileges
				on error
					return whichLanguage & ".lproj/NSProCommandDescriptions.strings"
			end try
			try
				do shell script "cp -f ~/.hammerspoon/hs/fcpxhacks/plist/10-3/new/" & whichLanguage & ".lproj/NSProCommandNames.strings '" & finalCutProPath & "/Contents/Resources/" & whichLanguage & ".lproj/NSProCommandNames.strings'" with administrator privileges
				on error
					return whichLanguage & ".lproj/NSProCommandNames.strings"
			end try
		end repeat
		return "Done"
	]]
	ok,result = osascript.applescript(appleScript)
	return result
end

--------------------------------------------------------------------------------
-- DISABLE HACKS SHORTCUTS:
--------------------------------------------------------------------------------
function disableHacksShortcuts()
	local appleScript = [[
		set finalCutProPath to "]] .. fcp:getPath() .. [["
		set finalCutProLanguages to ]] .. inspect(fcp:getSupportedLanguages()) .. [[

		try
			do shell script "cp -f ~/.hammerspoon/hs/fcpxhacks/plist/10-3/old/NSProCommandGroups.plist '" & finalCutProPath & "/Contents/Resources/NSProCommandGroups.plist'" with administrator privileges
			on error
				return "NSProCommandGroups.plist"
		end try
		try
			do shell script "cp -f ~/.hammerspoon/hs/fcpxhacks/plist/10-3/old/NSProCommands.plist '" & finalCutProPath & "/Contents/Resources/NSProCommands.plist'" with administrator privileges
			on error
				return "NSProCommands.plist"
		end try
		repeat with whichLanguage in finalCutProLanguages
			try
				do shell script "cp -f ~/.hammerspoon/hs/fcpxhacks/plist/10-3/old/" & whichLanguage & ".lproj/Default.commandset '" & finalCutProPath & "/Contents/Resources/" & whichLanguage & ".lproj/Default.commandset'" with administrator privileges
				on error
					return whichLanguage & ".lproj/Default.commandset"
			end try
			try
				do shell script "cp -f ~/.hammerspoon/hs/fcpxhacks/plist/10-3/old/" & whichLanguage & ".lproj/NSProCommandDescriptions.strings '" & finalCutProPath & "/Contents/Resources/" & whichLanguage & ".lproj/NSProCommandDescriptions.strings'" with administrator privileges
				on error
					return whichLanguage & ".lproj/NSProCommandDescriptions.strings"
			end try
			try
				do shell script "cp -f ~/.hammerspoon/hs/fcpxhacks/plist/10-3/old/" & whichLanguage & ".lproj/NSProCommandNames.strings '" & finalCutProPath & "/Contents/Resources/" & whichLanguage & ".lproj/NSProCommandNames.strings'" with administrator privileges
				on error
					return whichLanguage & ".lproj/NSProCommandNames.strings"
			end try
		end repeat
		return "Done"
	]]
	ok,result = osascript.applescript(appleScript)
	return result
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------





--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                     M E N U B A R    F E A T U R E S                       --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- MENUBAR:
--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- REFRESH MENUBAR:
	--------------------------------------------------------------------------------
	function refreshMenuBar(refreshPlistValues)

		--------------------------------------------------------------------------------
		-- Maximum Length of Menubar Strings:
		--------------------------------------------------------------------------------
		local maxTextLength = 25

		--------------------------------------------------------------------------------
		-- Assume FCPX is closed if not told otherwise:
		--------------------------------------------------------------------------------
		local fcpxActive = fcp:isFrontmost()
		local fcpxRunning = fcp:isRunning()

		--------------------------------------------------------------------------------
		-- Current Language:
		--------------------------------------------------------------------------------
		local currentLanguage = fcp:getCurrentLanguage()

		--------------------------------------------------------------------------------
		-- We only refresh plist values if necessary as this takes time:
		--------------------------------------------------------------------------------
		if refreshPlistValues == true then

			--------------------------------------------------------------------------------
			-- Used for debugging:
			--------------------------------------------------------------------------------
			debugMessage("Menubar refreshed with latest plist values.")

			--------------------------------------------------------------------------------
			-- Read Final Cut Pro Preferences:
			--------------------------------------------------------------------------------
			local preferences = fcp:getPreferences()
			if preferences == nil then
				dialog.displayErrorMessage(i18n("failedToReadFCPPreferences"))
				return "Fail"
			end

			--------------------------------------------------------------------------------
			-- Get plist values for Allow Moving Markers:
			--------------------------------------------------------------------------------
			mod.allowMovingMarkers = false
			local result = plist.fileToTable(fcp:getPath() .. "/Contents/Frameworks/TLKit.framework/Versions/A/Resources/EventDescriptions.plist")
			if result ~= nil then
				if result["TLKMarkerHandler"] ~= nil then
					if result["TLKMarkerHandler"]["Configuration"] ~= nil then
						if result["TLKMarkerHandler"]["Configuration"]["Allow Moving Markers"] ~= nil then
							mod.allowMovingMarkers = result["TLKMarkerHandler"]["Configuration"]["Allow Moving Markers"]
						end
					end
				end
			end

			--------------------------------------------------------------------------------
			-- Get plist values for FFPeriodicBackupInterval:
			--------------------------------------------------------------------------------
			if preferences["FFPeriodicBackupInterval"] == nil then
				mod.FFPeriodicBackupInterval = "15"
			else
				mod.FFPeriodicBackupInterval = preferences["FFPeriodicBackupInterval"]
			end

			--------------------------------------------------------------------------------
			-- Get plist values for FFSuspendBGOpsDuringPlay:
			--------------------------------------------------------------------------------
			if preferences["FFSuspendBGOpsDuringPlay"] == nil then
				mod.FFSuspendBGOpsDuringPlay = false
			else
				mod.FFSuspendBGOpsDuringPlay = preferences["FFSuspendBGOpsDuringPlay"]
			end

			--------------------------------------------------------------------------------
			-- Get plist values for FFEnableGuards:
			--------------------------------------------------------------------------------
			if preferences["FFEnableGuards"] == nil then
				mod.FFEnableGuards = false
			else
				mod.FFEnableGuards = preferences["FFEnableGuards"]
			end

			--------------------------------------------------------------------------------
			-- Get plist values for FFAutoRenderDelay:
			--------------------------------------------------------------------------------
			if preferences["FFAutoRenderDelay"] == nil then
				mod.FFAutoRenderDelay = "0.3"
			else
				mod.FFAutoRenderDelay = preferences["FFAutoRenderDelay"]
			end

		end

		--------------------------------------------------------------------------------
		-- Get Menubar Display Mode from Settings:
		--------------------------------------------------------------------------------
		local displayMenubarAsIcon = settings.get("fcpxHacks.displayMenubarAsIcon") or false

		--------------------------------------------------------------------------------
		-- Get Sizing Preferences:
		--------------------------------------------------------------------------------
		local displayHighlightShape = nil
		displayHighlightShape = settings.get("fcpxHacks.displayHighlightShape")
		local displayHighlightShapeRectangle = false
		local displayHighlightShapeCircle = false
		local displayHighlightShapeDiamond = false
		if displayHighlightShape == nil then 			displayHighlightShapeRectangle = true		end
		if displayHighlightShape == "Rectangle" then 	displayHighlightShapeRectangle = true		end
		if displayHighlightShape == "Circle" then 		displayHighlightShapeCircle = true			end
		if displayHighlightShape == "Diamond" then 		displayHighlightShapeDiamond = true			end

		--------------------------------------------------------------------------------
		-- Get Highlight Colour Preferences:
		--------------------------------------------------------------------------------
		local displayHighlightColour = settings.get("fcpxHacks.displayHighlightColour") or nil

		--------------------------------------------------------------------------------
		-- Get Highlight Playhead Time:
		--------------------------------------------------------------------------------
		local highlightPlayheadTime = settings.get("fcpxHacks.highlightPlayheadTime")

		--------------------------------------------------------------------------------
		-- Get Enable Shortcuts During Fullscreen Playback from Settings:
		--------------------------------------------------------------------------------
		local enableShortcutsDuringFullscreenPlayback = settings.get("fcpxHacks.enableShortcutsDuringFullscreenPlayback") or false

		--------------------------------------------------------------------------------
		-- Get Enable Hacks Shortcuts in Final Cut Pro from Settings:
		--------------------------------------------------------------------------------
		local enableHacksShortcutsInFinalCutPro = settings.get("fcpxHacks.enableHacksShortcutsInFinalCutPro") or false

		--------------------------------------------------------------------------------
		-- Get Enable Proxy Menu Item:
		--------------------------------------------------------------------------------
		local enableProxyMenuIcon = settings.get("fcpxHacks.enableProxyMenuIcon") or false

		--------------------------------------------------------------------------------
		-- Hammerspoon Settings:
		--------------------------------------------------------------------------------
		local startHammerspoonOnLaunch = hs.autoLaunch()
		local hammerspoonCheckForUpdates = hs.automaticallyCheckForUpdates()
		local hammerspoonDockIcon = hs.dockIcon()
		local hammerspoonMenuIcon = hs.menuIcon()

		--------------------------------------------------------------------------------
		-- Scrolling Timeline:
		--------------------------------------------------------------------------------
		scrollingTimelineActive = settings.get("fcpxHacks.scrollingTimelineActive") or false

		--------------------------------------------------------------------------------
		-- Enable Mobile Notifications:
		--------------------------------------------------------------------------------
		enableMobileNotifications = settings.get("fcpxHacks.enableMobileNotifications") or false

		--------------------------------------------------------------------------------
		-- Enable Media Import Watcher:
		--------------------------------------------------------------------------------
		enableMediaImportWatcher = settings.get("fcpxHacks.enableMediaImportWatcher") or false

		--------------------------------------------------------------------------------
		-- Touch Bar Location:
		--------------------------------------------------------------------------------
		local displayTouchBarLocation = settings.get("fcpxHacks.displayTouchBarLocation") or "Mouse"
		local displayTouchBarLocationMouse = false
		if displayTouchBarLocation == "Mouse" then displayTouchBarLocationMouse = true end
		local displayTouchBarLocationTimelineTopCentre = false
		if displayTouchBarLocation == "TimelineTopCentre" then displayTouchBarLocationTimelineTopCentre = true end

		--------------------------------------------------------------------------------
		-- Display Touch Bar:
		--------------------------------------------------------------------------------
		local displayTouchBar = settings.get("fcpxHacks.displayTouchBar") or false

		--------------------------------------------------------------------------------
		-- Enable Check for Updates:
		--------------------------------------------------------------------------------
		local enableCheckForUpdates = settings.get("fcpxHacks.enableCheckForUpdates") or false

		--------------------------------------------------------------------------------
		-- Enable XML Sharing:
		--------------------------------------------------------------------------------
		local enableXMLSharing 		= settings.get("fcpxHacks.enableXMLSharing") or false

		--------------------------------------------------------------------------------
		-- Enable Clipboard History:
		--------------------------------------------------------------------------------
		local enableClipboardHistory = settings.get("fcpxHacks.enableClipboardHistory") or false

		--------------------------------------------------------------------------------
		-- Enable Shared Clipboard:
		--------------------------------------------------------------------------------
		local enableSharedClipboard = settings.get("fcpxHacks.enableSharedClipboard") or false

		--------------------------------------------------------------------------------
		-- Enable Hacks HUD:
		--------------------------------------------------------------------------------
		local enableHacksHUD 		= settings.get("fcpxHacks.enableHacksHUD") or false

		local hudShowInspector 		= settings.get("fcpxHacks.hudShowInspector")
		local hudShowDropTargets 	= settings.get("fcpxHacks.hudShowDropTargets")
		local hudShowButtons 		= settings.get("fcpxHacks.hudShowButtons")

		local hudButtonOne 			= settings.get("fcpxHacks." .. currentLanguage .. ".hudButtonOne") 	or " (Unassigned)"
		local hudButtonTwo 			= settings.get("fcpxHacks." .. currentLanguage .. ".hudButtonTwo") 	or " (Unassigned)"
		local hudButtonThree 		= settings.get("fcpxHacks." .. currentLanguage .. ".hudButtonThree") 	or " (Unassigned)"
		local hudButtonFour 		= settings.get("fcpxHacks." .. currentLanguage .. ".hudButtonFour") 	or " (Unassigned)"

		if hudButtonOne ~= " (Unassigned)" then		hudButtonOne = " (" .. 		tools.stringMaxLength(tools.cleanupButtonText(hudButtonOne["text"]),maxTextLength,"...") 	.. ")" end
		if hudButtonTwo ~= " (Unassigned)" then 	hudButtonTwo = " (" .. 		tools.stringMaxLength(tools.cleanupButtonText(hudButtonTwo["text"]),maxTextLength,"...") 	.. ")" end
		if hudButtonThree ~= " (Unassigned)" then 	hudButtonThree = " (" .. 	tools.stringMaxLength(tools.cleanupButtonText(hudButtonThree["text"]),maxTextLength,"...") 	.. ")" end
		if hudButtonFour ~= " (Unassigned)" then 	hudButtonFour = " (" .. 	tools.stringMaxLength(tools.cleanupButtonText(hudButtonFour["text"]),maxTextLength,"...") 	.. ")" end

		--------------------------------------------------------------------------------
		-- Clipboard History Menu:
		--------------------------------------------------------------------------------
		local settingsClipboardHistoryTable = {}
		if enableClipboardHistory then
			local clipboardHistory = clipboard.getHistory()
			if clipboardHistory ~= nil then
				if #clipboardHistory ~= 0 then
					for i=#clipboardHistory, 1, -1 do
						table.insert(settingsClipboardHistoryTable, {title = clipboardHistory[i][2], fn = function() finalCutProPasteFromClipboardHistory(clipboardHistory[i][1]) end, disabled = not fcpxRunning})
					end
					table.insert(settingsClipboardHistoryTable, { title = "-" })
					table.insert(settingsClipboardHistoryTable, { title = "Clear Clipboard History", fn = clearClipboardHistory })
				else
					table.insert(settingsClipboardHistoryTable, { title = "Empty", disabled = true })
				end
			end
		else
			table.insert(settingsClipboardHistoryTable, { title = "Disabled in Settings", disabled = true })
		end

		--------------------------------------------------------------------------------
		-- Shared Clipboard Menu:
		--------------------------------------------------------------------------------
		local settingsSharedClipboardTable = {}

		if enableSharedClipboard and enableClipboardHistory then

			--------------------------------------------------------------------------------
			-- Get list of files:
			--------------------------------------------------------------------------------
			local emptySharedClipboard = true
			local sharedClipboardFiles = {}
			local sharedClipboardPath = settings.get("fcpxHacks.sharedClipboardPath")
			for file in fs.dir(sharedClipboardPath) do
				 if file:sub(-10) == ".fcpxhacks" then

					local pathToClipboardFile = sharedClipboardPath .. file
					local plistData = plist.xmlFileToTable(pathToClipboardFile)
					if plistData ~= nil then
						if plistData["SharedClipboardLabel1"] ~= nil then

							local editorName = string.sub(file, 1, -11)
							local submenu = {}
							for i=1, 5 do
								emptySharedClipboard = false
								local currentItem = plistData["SharedClipboardLabel"..tostring(i)]
								if currentItem ~= "" then table.insert(submenu, {title = currentItem, fn = function() pasteFromSharedClipboard(pathToClipboardFile, tostring(i)) end, disabled = not fcpxRunning}) end
							end

							table.insert(settingsSharedClipboardTable, {title = editorName, menu = submenu})
						end
					end


				 end
			end

			if emptySharedClipboard then
				--------------------------------------------------------------------------------
				-- Nothing in the Shared Clipboard:
				--------------------------------------------------------------------------------
				table.insert(settingsSharedClipboardTable, { title = "Empty", disabled = true })
			else
				table.insert(settingsSharedClipboardTable, { title = "-" })
				table.insert(settingsSharedClipboardTable, { title = "Clear Shared Clipboard History", fn = clearSharedClipboardHistory })
			end

		else
			--------------------------------------------------------------------------------
			-- Shared Clipboard Disabled:
			--------------------------------------------------------------------------------
			table.insert(settingsSharedClipboardTable, { title = "Disabled in Settings", disabled = true })
		end

		--------------------------------------------------------------------------------
		-- Shared XML Menu:
		--------------------------------------------------------------------------------
		local settingsSharedXMLTable = {}
		if enableXMLSharing then

			--------------------------------------------------------------------------------
			-- Get list of files:
			--------------------------------------------------------------------------------
			local sharedXMLFiles = {}

			local emptySharedXMLFiles = true
			local xmlSharingPath = settings.get("fcpxHacks.xmlSharingPath")

			for folder in fs.dir(xmlSharingPath) do

				if tools.doesDirectoryExist(xmlSharingPath .. "/" .. folder) then

					submenu = {}
					for file in fs.dir(xmlSharingPath .. "/" .. folder) do
						if file:sub(-7) == ".fcpxml" then
							emptySharedXMLFiles = false
							local xmlPath = xmlSharingPath .. folder .. "/" .. file
							table.insert(submenu, {title = file:sub(1, -8), fn = function() fcp:importXML(xmlPath) end, disabled = not fcpxRunning})
						end
					end

					if next(submenu) ~= nil then
						table.insert(settingsSharedXMLTable, {title = folder, menu = submenu})
					end

				end

			end

			if emptySharedXMLFiles then
				--------------------------------------------------------------------------------
				-- Nothing in the Shared Clipboard:
				--------------------------------------------------------------------------------
				table.insert(settingsSharedXMLTable, { title = "Empty", disabled = true })
			else
				--------------------------------------------------------------------------------
				-- Something in the Shared Clipboard:
				--------------------------------------------------------------------------------
				table.insert(settingsSharedXMLTable, { title = "-" })
				table.insert(settingsSharedXMLTable, { title = "Clear Shared XML Files", fn = clearSharedXMLFiles })
			end
		else
			--------------------------------------------------------------------------------
			-- Shared Clipboard Disabled:
			--------------------------------------------------------------------------------
			table.insert(settingsSharedXMLTable, { title = "Disabled in Settings", disabled = true })
		end

		--------------------------------------------------------------------------------
		-- Lock Timeline Playhead:
		--------------------------------------------------------------------------------
		local lockTimelinePlayhead = settings.get("fcpxHacks.lockTimelinePlayhead") or false

		--------------------------------------------------------------------------------
		-- Effects Shortcuts:
		--------------------------------------------------------------------------------
		local effectsListUpdated 	= settings.get("fcpxHacks." .. currentLanguage .. ".effectsListUpdated") or false
		local effectsShortcutOne 	= settings.get("fcpxHacks." .. currentLanguage .. ".effectsShortcutOne")
		local effectsShortcutTwo 	= settings.get("fcpxHacks." .. currentLanguage .. ".effectsShortcutTwo")
		local effectsShortcutThree 	= settings.get("fcpxHacks." .. currentLanguage .. ".effectsShortcutThree")
		local effectsShortcutFour 	= settings.get("fcpxHacks." .. currentLanguage .. ".effectsShortcutFour")
		local effectsShortcutFive 	= settings.get("fcpxHacks." .. currentLanguage .. ".effectsShortcutFive")
		if effectsShortcutOne == nil then 		effectsShortcutOne = " (Unassigned)" 		else effectsShortcutOne = " (" .. tools.stringMaxLength(effectsShortcutOne,maxTextLength,"...") .. ")" end
		if effectsShortcutTwo == nil then 		effectsShortcutTwo = " (Unassigned)" 		else effectsShortcutTwo = " (" .. tools.stringMaxLength(effectsShortcutTwo,maxTextLength,"...") .. ")" end
		if effectsShortcutThree == nil then 	effectsShortcutThree = " (Unassigned)" 		else effectsShortcutThree = " (" .. tools.stringMaxLength(effectsShortcutThree,maxTextLength,"...") .. ")" end
		if effectsShortcutFour == nil then 		effectsShortcutFour = " (Unassigned)" 		else effectsShortcutFour = " (" .. tools.stringMaxLength(effectsShortcutFour,maxTextLength,"...") .. ")" end
		if effectsShortcutFive == nil then 		effectsShortcutFive = " (Unassigned)" 		else effectsShortcutFive = " (" .. tools.stringMaxLength(effectsShortcutFive,maxTextLength,"...") .. ")" end

		--------------------------------------------------------------------------------
		-- Transition Shortcuts:
		--------------------------------------------------------------------------------
		local transitionsListUpdated 	= settings.get("fcpxHacks." .. currentLanguage .. ".transitionsListUpdated") or false
		local transitionsShortcutOne 	= settings.get("fcpxHacks." .. currentLanguage .. ".transitionsShortcutOne")
		local transitionsShortcutTwo 	= settings.get("fcpxHacks." .. currentLanguage .. ".transitionsShortcutTwo")
		local transitionsShortcutThree 	= settings.get("fcpxHacks." .. currentLanguage .. ".transitionsShortcutThree")
		local transitionsShortcutFour 	= settings.get("fcpxHacks." .. currentLanguage .. ".transitionsShortcutFour")
		local transitionsShortcutFive 	= settings.get("fcpxHacks." .. currentLanguage .. ".transitionsShortcutFive")
		if transitionsShortcutOne == nil then 		transitionsShortcutOne = " (Unassigned)" 		else transitionsShortcutOne 	= " (" .. tools.stringMaxLength(transitionsShortcutOne,maxTextLength,"...") .. ")" 	end
		if transitionsShortcutTwo == nil then 		transitionsShortcutTwo = " (Unassigned)" 		else transitionsShortcutTwo 	= " (" .. tools.stringMaxLength(transitionsShortcutTwo,maxTextLength,"...") .. ")" 	end
		if transitionsShortcutThree == nil then 	transitionsShortcutThree = " (Unassigned)" 		else transitionsShortcutThree 	= " (" .. tools.stringMaxLength(transitionsShortcutThree,maxTextLength,"...") .. ")"	end
		if transitionsShortcutFour == nil then 		transitionsShortcutFour = " (Unassigned)" 		else transitionsShortcutFour 	= " (" .. tools.stringMaxLength(transitionsShortcutFour,maxTextLength,"...") .. ")" 	end
		if transitionsShortcutFive == nil then 		transitionsShortcutFive = " (Unassigned)" 		else transitionsShortcutFive 	= " (" .. tools.stringMaxLength(transitionsShortcutFive,maxTextLength,"...") .. ")" 	end

		--------------------------------------------------------------------------------
		-- Titles Shortcuts:
		--------------------------------------------------------------------------------
		local titlesListUpdated 	= settings.get("fcpxHacks." .. currentLanguage .. ".titlesListUpdated") or false
		local titlesShortcutOne 	= settings.get("fcpxHacks." .. currentLanguage .. ".titlesShortcutOne")
		local titlesShortcutTwo 	= settings.get("fcpxHacks." .. currentLanguage .. ".titlesShortcutTwo")
		local titlesShortcutThree 	= settings.get("fcpxHacks." .. currentLanguage .. ".titlesShortcutThree")
		local titlesShortcutFour 	= settings.get("fcpxHacks." .. currentLanguage .. ".titlesShortcutFour")
		local titlesShortcutFive 	= settings.get("fcpxHacks." .. currentLanguage .. ".titlesShortcutFive")
		if titlesShortcutOne == nil then 		titlesShortcutOne = " (Unassigned)" 		else titlesShortcutOne 	= " (" .. tools.stringMaxLength(titlesShortcutOne,maxTextLength,"...") .. ")" 	end
		if titlesShortcutTwo == nil then 		titlesShortcutTwo = " (Unassigned)" 		else titlesShortcutTwo 	= " (" .. tools.stringMaxLength(titlesShortcutTwo,maxTextLength,"...") .. ")" 	end
		if titlesShortcutThree == nil then 		titlesShortcutThree = " (Unassigned)" 		else titlesShortcutThree 	= " (" .. tools.stringMaxLength(titlesShortcutThree,maxTextLength,"...") .. ")"	end
		if titlesShortcutFour == nil then 		titlesShortcutFour = " (Unassigned)" 		else titlesShortcutFour 	= " (" .. tools.stringMaxLength(titlesShortcutFour,maxTextLength,"...") .. ")" 	end
		if titlesShortcutFive == nil then 		titlesShortcutFive = " (Unassigned)" 		else titlesShortcutFive 	= " (" .. tools.stringMaxLength(titlesShortcutFive,maxTextLength,"...") .. ")" 	end

		--------------------------------------------------------------------------------
		-- Generators Shortcuts:
		--------------------------------------------------------------------------------
		local generatorsListUpdated 	= settings.get("fcpxHacks." .. currentLanguage .. ".generatorsListUpdated") or false
		local generatorsShortcutOne 	= settings.get("fcpxHacks." .. currentLanguage .. ".generatorsShortcutOne")
		local generatorsShortcutTwo 	= settings.get("fcpxHacks." .. currentLanguage .. ".generatorsShortcutTwo")
		local generatorsShortcutThree 	= settings.get("fcpxHacks." .. currentLanguage .. ".generatorsShortcutThree")
		local generatorsShortcutFour 	= settings.get("fcpxHacks." .. currentLanguage .. ".generatorsShortcutFour")
		local generatorsShortcutFive 	= settings.get("fcpxHacks." .. currentLanguage .. ".generatorsShortcutFive")
		if generatorsShortcutOne == nil then 		generatorsShortcutOne = " (Unassigned)" 		else generatorsShortcutOne 	= " (" .. tools.stringMaxLength(generatorsShortcutOne,maxTextLength,"...") .. ")" 	end
		if generatorsShortcutTwo == nil then 		generatorsShortcutTwo = " (Unassigned)" 		else generatorsShortcutTwo 	= " (" .. tools.stringMaxLength(generatorsShortcutTwo,maxTextLength,"...") .. ")" 	end
		if generatorsShortcutThree == nil then 		generatorsShortcutThree = " (Unassigned)" 		else generatorsShortcutThree 	= " (" .. tools.stringMaxLength(generatorsShortcutThree,maxTextLength,"...") .. ")"	end
		if generatorsShortcutFour == nil then 		generatorsShortcutFour = " (Unassigned)" 		else generatorsShortcutFour 	= " (" .. tools.stringMaxLength(generatorsShortcutFour,maxTextLength,"...") .. ")" 	end
		if generatorsShortcutFive == nil then 		generatorsShortcutFive = " (Unassigned)" 		else generatorsShortcutFive 	= " (" .. tools.stringMaxLength(generatorsShortcutFive,maxTextLength,"...") .. ")" 	end

		--------------------------------------------------------------------------------
		-- Get Menubar Settings:
		--------------------------------------------------------------------------------
		local menubarShortcutsEnabled = 	settings.get("fcpxHacks.menubarShortcutsEnabled")
		local menubarAutomationEnabled = 	settings.get("fcpxHacks.menubarAutomationEnabled")
		local menubarToolsEnabled = 		settings.get("fcpxHacks.menubarToolsEnabled")
		local menubarHacksEnabled = 		settings.get("fcpxHacks.menubarHacksEnabled")

		--------------------------------------------------------------------------------
		-- Are Hacks Shortcuts Enabled or Not:
		--------------------------------------------------------------------------------
		local displayShortcutText = i18n("displayKeyboardShortcuts")
		if enableHacksShortcutsInFinalCutPro then displayShortcutText = i18n("openCommandEditor") end

		--------------------------------------------------------------------------------
		-- FCPX Hacks Languages:
		--------------------------------------------------------------------------------
		local settingsLanguage = {}

		local userLocale = nil
		if settings.get("fcpxHacks.language") == nil then
			userLocale = tools.userLocale()
		else
			userLocale = settings.get("fcpxHacks.language")
		end

		local basicUserLocale = nil
		if string.find(userLocale, "_") ~= nil then
			basicUserLocale = string.sub(userLocale, 1, string.find(userLocale, "_") - 1)
		else
			basicUserLocale = userLocale
		end

		for i=1, #mod.installedLanguages do
			settingsLanguage[#settingsLanguage + 1] = { title = mod.installedLanguages[i]["language"], fn = function()
				settings.set("fcpxHacks.language", mod.installedLanguages[i]["id"])
				i18n.setLocale(mod.installedLanguages[i]["id"])
				refreshMenuBar()
			end, checked = (userLocale == mod.installedLanguages[i]["id"] or basicUserLocale == mod.installedLanguages[i]["id"]), }
		end

		--------------------------------------------------------------------------------
		-- Setup Menu:
		--------------------------------------------------------------------------------
		local settingsShapeMenuTable = {
			{ title = i18n("rectangle"), 																fn = function() changeHighlightShape("Rectangle") end,				checked = displayHighlightShapeRectangle	},
			{ title = i18n("circle"), 																	fn = function() changeHighlightShape("Circle") end, 				checked = displayHighlightShapeCircle		},
			{ title = i18n("diamond"),																	fn = function() changeHighlightShape("Diamond") end, 				checked = displayHighlightShapeDiamond		},
		}
		local settingsColourMenuTable = {
			{ title = i18n("red"), 																		fn = function() changeHighlightColour("Red") end, 					checked = displayHighlightColour == "Red" },
			{ title = i18n("blue"), 																	fn = function() changeHighlightColour("Blue") end, 					checked = displayHighlightColour == "Blue" },
			{ title = i18n("green"), 																	fn = function() changeHighlightColour("Green") end, 				checked = displayHighlightColour == "Green"	},
			{ title = i18n("yellow"), 																	fn = function() changeHighlightColour("Yellow") end, 				checked = displayHighlightColour == "Yellow" },
			{ title = "-" },
			{ title = i18n("custom"), 																	fn = function() changeHighlightColour("Custom") end, 				checked = displayHighlightColour == "Custom" },
		}
		local settingsHammerspoonSettings = {
			{ title = i18n("console") .. "...", 														fn = openHammerspoonConsole },
			{ title = "-" },
			{ title = i18n("showDockIcon"),																fn = toggleHammerspoonDockIcon, 									checked = hammerspoonDockIcon		},
			{ title = i18n("showMenuIcon"), 															fn = toggleHammerspoonMenuIcon, 									checked = hammerspoonMenuIcon		},
			{ title = "-" },
			{ title = i18n("launchAtStartup"), 															fn = toggleLaunchHammerspoonOnStartup, 								checked = startHammerspoonOnLaunch		},
			{ title = i18n("checkForUpdates"), 															fn = toggleCheckforHammerspoonUpdates, 								checked = hammerspoonCheckForUpdates	},
		}
		local settingsTouchBarLocation = {
			{ title = i18n("mouseLocation"), 															fn = function() changeTouchBarLocation("Mouse") end,				checked = displayTouchBarLocationMouse, disabled = not touchBarSupported },
			{ title = i18n("topCentreOfTimeline"), 														fn = function() changeTouchBarLocation("TimelineTopCentre") end,	checked = displayTouchBarLocationTimelineTopCentre, disabled = not touchBarSupported },
			{ title = "-" },
			{ title = i18n("touchBarTipOne"), 															disabled = true },
			{ title = i18n("touchBarTipTwo"), 															disabled = true },
		}
		local settingsMenubar = {
			{ title = i18n("showShortcuts"), 															fn = function() toggleMenubarDisplay("Shortcuts") end, 				checked = menubarShortcutsEnabled},
			{ title = i18n("showAutomation"), 															fn = function() toggleMenubarDisplay("Automation") end, 			checked = menubarAutomationEnabled},
			{ title = i18n("showTools"), 																fn = function() toggleMenubarDisplay("Tools") end, 					checked = menubarToolsEnabled},
			{ title = i18n("showHacks"), 																fn = function() toggleMenubarDisplay("Hacks") end, 					checked = menubarHacksEnabled},
			{ title = "-" },
			{ title = i18n("displayProxyOriginalIcon"), 												fn = toggleEnableProxyMenuIcon, 									checked = enableProxyMenuIcon},
			{ title = i18n("displayThisMenuAsIcon"), 													fn = toggleMenubarDisplayMode, 										checked = displayMenubarAsIcon},
		}
		local settingsHUD = {
			{ title = i18n("showInspector"), 															fn = function() toggleHUDOption("hudShowInspector") end, 			checked = hudShowInspector},
			{ title = i18n("showDropTargets"), 															fn = function() toggleHUDOption("hudShowDropTargets") end, 			checked = hudShowDropTargets},
			{ title = i18n("showButtons"), 																fn = function() toggleHUDOption("hudShowButtons") end, 				checked = hudShowButtons},
		}
		local menuLanguage = {
			{ title = i18n("german"), 																	fn = function() changeFinalCutProLanguage("de") end, 				checked = currentLanguage == "de"},
			{ title = i18n("english"), 																	fn = function() changeFinalCutProLanguage("en") end, 				checked = currentLanguage == "en"},
			{ title = i18n("spanish"), 																	fn = function() changeFinalCutProLanguage("es") end, 				checked = currentLanguage == "es"},
			{ title = i18n("french"), 																	fn = function() changeFinalCutProLanguage("fr") end, 				checked = currentLanguage == "fr"},
			{ title = i18n("japanese"), 																fn = function() changeFinalCutProLanguage("ja") end, 				checked = currentLanguage == "ja"},
			{ title = i18n("chineseChina"), 															fn = function() changeFinalCutProLanguage("zh_CN") end, 			checked = currentLanguage == "zh_CN"},
		}
		local settingsBatchExportOptions = {
			{ title = i18n("setDestinationPreset"), 													fn = changeBatchExportDestinationPreset, 							disabled = not fcpxRunning },
			{ title = i18n("setDestinationFolder"), 													fn = changeBatchExportDestinationFolder },
			{ title = "-" },
			{ title = i18n("replaceExistingFiles"), 													fn = toggleBatchExportReplaceExistingFiles, 						checked = settings.get("fcpxHacks.batchExportReplaceExistingFiles") },
		}

		local settingsVoiceCommand = {
			{ title = i18n("enableAnnouncements"), 														fn = toggleVoiceCommandEnableAnnouncements, 						checked = settings.get("fcpxHacks.voiceCommandEnableAnnouncements") },
			{ title = i18n("enableVisualAlerts"), 														fn = toggleVoiceCommandEnableVisualAlerts, 							checked = settings.get("fcpxHacks.voiceCommandEnableVisualAlerts") },
			{ title = "-" },
			{ title = i18n("openDictationPreferences"), 												fn = function()
				osascript.applescript([[
					tell application "System Preferences"
						activate
						reveal anchor "Dictation" of pane "com.apple.preference.speech"
					end tell]]) end },
		}
		local settingsHighlightPlayheadTime = {
			{ title = i18n("one") .. " " .. i18n("secs", {count=1}), 									fn = function() changeHighlightPlayheadTime(1) end, 					checked = highlightPlayheadTime == 1 },
			{ title = i18n("two") .. " " .. i18n("secs", {count=2}), 									fn = function() changeHighlightPlayheadTime(2) end, 					checked = highlightPlayheadTime == 2 },
			{ title = i18n("three") .. " " .. i18n("secs", {count=2}), 									fn = function() changeHighlightPlayheadTime(3) end, 					checked = highlightPlayheadTime == 3 },
			{ title = i18n("four") .. " " .. i18n("secs", {count=2}), 									fn = function() changeHighlightPlayheadTime(4) end, 					checked = highlightPlayheadTime == 4 },
			{ title = i18n("five") .. " " .. i18n("secs", {count=2}), 									fn = function() changeHighlightPlayheadTime(5) end, 					checked = highlightPlayheadTime == 5 },
			{ title = i18n("six") .. " " .. i18n("secs", {count=2}), 									fn = function() changeHighlightPlayheadTime(6) end, 					checked = highlightPlayheadTime == 6 },
			{ title = i18n("seven") .. " " .. i18n("secs", {count=2}), 									fn = function() changeHighlightPlayheadTime(7) end, 					checked = highlightPlayheadTime == 7 },
			{ title = i18n("eight") .. " " .. i18n("secs", {count=2}), 									fn = function() changeHighlightPlayheadTime(8) end, 					checked = highlightPlayheadTime == 8 },
			{ title = i18n("nine") .. " " .. i18n("secs", {count=2}), 									fn = function() changeHighlightPlayheadTime(9) end, 					checked = highlightPlayheadTime == 9 },
			{ title = i18n("ten") .. " " .. i18n("secs", {count=2}), 									fn = function() changeHighlightPlayheadTime(10) end, 					checked = highlightPlayheadTime == 10 },
		}
		local settingsMenuTable = {
			{ title = i18n("finalCutProLanguage"), 														menu = menuLanguage },
			{ title = "FCPX Hacks " .. i18n("language"), 												menu = settingsLanguage},
			{ title = "-" },
			{ title = i18n("batchExportOptions"), 														menu = settingsBatchExportOptions},
			{ title = "-" },
			{ title = i18n("menubarOptions"), 															menu = settingsMenubar},
			{ title = i18n("hudOptions"), 																menu = settingsHUD},
			{ title = i18n("voiceCommandOptions"), 														menu = settingsVoiceCommand},
			{ title = "Hammerspoon " .. i18n("options"),												menu = settingsHammerspoonSettings},
			{ title = "-" },
			{ title = i18n("touchBarLocation"), 														menu = settingsTouchBarLocation},
			{ title = "-" },
			{ title = i18n("highlightPlayheadColour"), 													menu = settingsColourMenuTable},
			{ title = i18n("highlightPlayheadShape"), 													menu = settingsShapeMenuTable},
			{ title = i18n("highlightPlayheadTime"), 													menu = settingsHighlightPlayheadTime},
			{ title = "-" },
			{ title = i18n("checkForUpdates"), 															fn = toggleCheckForUpdates, 										checked = enableCheckForUpdates},
			{ title = i18n("enableDebugMode"), 															fn = toggleDebugMode, 												checked = mod.debugMode},
			{ title = "-" },
			{ title = i18n("trachFCPXHacksPreferences"), 												fn = resetSettings },
			{ title = "-" },
			{ title = i18n("provideFeedback"),															fn = emailBugReport },
			{ title = "-" },
			{ title = i18n("createdBy") .. " LateNite Films", 											fn = gotoLateNiteSite },
			{ title = i18n("scriptVersion") .. " " .. fcpxhacks.scriptVersion,							disabled = true },
		}
		local settingsEffectsShortcutsTable = {
			{ title = i18n("updateEffectsList"),														fn = updateEffectsList, 																										disabled = not fcpxRunning },
			{ title = "-" },
			{ title = i18n("effectShortcut") .. " " .. i18n("one") .. effectsShortcutOne, 				fn = function() assignEffectsShortcut(1) end, 																					disabled = not effectsListUpdated },
			{ title = i18n("effectShortcut") .. " " .. i18n("two") .. effectsShortcutTwo, 				fn = function() assignEffectsShortcut(2) end, 																					disabled = not effectsListUpdated },
			{ title = i18n("effectShortcut") .. " " .. i18n("three") .. effectsShortcutThree, 			fn = function() assignEffectsShortcut(3) end, 																					disabled = not effectsListUpdated },
			{ title = i18n("effectShortcut") .. " " .. i18n("four") .. effectsShortcutFour, 			fn = function() assignEffectsShortcut(4) end, 																					disabled = not effectsListUpdated },
			{ title = i18n("effectShortcut") .. " " .. i18n("five") .. effectsShortcutFive, 			fn = function() assignEffectsShortcut(5) end, 																					disabled = not effectsListUpdated },
		}
		local settingsTransitionsShortcutsTable = {
			{ title = i18n("updateTransitionsList"), 													fn = updateTransitionsList, 																									disabled = not fcpxRunning },
			{ title = "-" },
			{ title = i18n("transitionShortcut") .. " " .. i18n("one") .. transitionsShortcutOne, 		fn = function() assignTransitionsShortcut(1) end,																				disabled = not transitionsListUpdated },
			{ title = i18n("transitionShortcut") .. " " .. i18n("two") .. transitionsShortcutTwo, 		fn = function() assignTransitionsShortcut(2) end, 																				disabled = not transitionsListUpdated },
			{ title = i18n("transitionShortcut") .. " " .. i18n("three") .. transitionsShortcutThree, 	fn = function() assignTransitionsShortcut(3) end, 																				disabled = not transitionsListUpdated },
			{ title = i18n("transitionShortcut") .. " " .. i18n("four") ..transitionsShortcutFour, 		fn = function() assignTransitionsShortcut(4) end, 																				disabled = not transitionsListUpdated },
			{ title = i18n("transitionShortcut") .. " " .. i18n("five") .. transitionsShortcutFive, 	fn = function() assignTransitionsShortcut(5) end, 																				disabled = not transitionsListUpdated },
		}
		local settingsTitlesShortcutsTable = {
			{ title = i18n("updateTitlesList"), 														fn = updateTitlesList, 																											disabled = not fcpxRunning },
			{ title = "-" },
			{ title = i18n("titleShortcut") .. " " .. i18n("one") .. titlesShortcutOne, 				fn = function() assignTitlesShortcut(1) end,																					disabled = not titlesListUpdated },
			{ title = i18n("titleShortcut") .. " " .. i18n("two") .. titlesShortcutTwo, 				fn = function() assignTitlesShortcut(2) end, 																					disabled = not titlesListUpdated },
			{ title = i18n("titleShortcut") .. " " .. i18n("three") .. titlesShortcutThree, 			fn = function() assignTitlesShortcut(3) end, 																					disabled = not titlesListUpdated },
			{ title = i18n("titleShortcut") .. " " .. i18n("four") .. titlesShortcutFour, 				fn = function() assignTitlesShortcut(4) end, 																					disabled = not titlesListUpdated },
			{ title = i18n("titleShortcut") .. " " .. i18n("five") .. titlesShortcutFive, 				fn = function() assignTitlesShortcut(5) end, 																					disabled = not titlesListUpdated },
		}
		local settingsGeneratorsShortcutsTable = {
			{ title = i18n("updateGeneratorsList"), 													fn = updateGeneratorsList, 																										disabled = not fcpxRunning },
			{ title = "-" },
			{ title = i18n("generatorShortcut") .. " " .. i18n("one") .. generatorsShortcutOne, 		fn = function() assignGeneratorsShortcut(1) end,																				disabled = not generatorsListUpdated },
			{ title = i18n("generatorShortcut") .. " " .. i18n("two") .. generatorsShortcutTwo, 		fn = function() assignGeneratorsShortcut(2) end, 																				disabled = not generatorsListUpdated },
			{ title = i18n("generatorShortcut") .. " " .. i18n("three") .. generatorsShortcutThree, 	fn = function() assignGeneratorsShortcut(3) end, 																				disabled = not generatorsListUpdated },
			{ title = i18n("generatorShortcut") .. " " .. i18n("four") .. generatorsShortcutFour, 		fn = function() assignGeneratorsShortcut(4) end, 																				disabled = not generatorsListUpdated },
			{ title = i18n("generatorShortcut") .. " " .. i18n("five") .. generatorsShortcutFive, 		fn = function() assignGeneratorsShortcut(5) end, 																				disabled = not generatorsListUpdated },
		}
		local settingsHUDButtons = {
			{ title = i18n("button") .. " " .. i18n("one") .. hudButtonOne, 							fn = function() hackshud.assignButton(1) end },
			{ title = i18n("button") .. " " .. i18n("two") .. hudButtonTwo, 							fn = function() hackshud.assignButton(2) end },
			{ title = i18n("button") .. " " .. i18n("three") .. hudButtonThree, 						fn = function() hackshud.assignButton(3) end },
			{ title = i18n("button") .. " " .. i18n("four") .. hudButtonFour, 							fn = function() hackshud.assignButton(4) end },
		}
		local menuTable = {
			{ title = i18n("open") .. " Final Cut Pro", 												fn = function() fcp:launch() end },
			{ title = displayShortcutText, 																fn = displayShortcutList, disabled = not fcpxRunning and enableHacksShortcutsInFinalCutPro },
			{ title = "-" },
		}
		local shortcutsTable = {
			{ title = string.upper(i18n("shortcuts")) .. ":", 											disabled = true },
			{ title = i18n("createOptimizedMedia"), 													fn = function() toggleCreateOptimizedMedia() end, 					checked = fcp:getPreference("FFImportCreateOptimizeMedia", false),				disabled = not fcpxRunning },
			{ title = i18n("createMulticamOptimizedMedia"),												fn = function() toggleCreateMulticamOptimizedMedia() end, 			checked = fcp:getPreference("FFCreateOptimizedMediaForMulticamClips", true), 	disabled = not fcpxRunning },
			{ title = i18n("createProxyMedia"), 														fn = function() toggleCreateProxyMedia() end, 						checked = fcp:getPreference("FFImportCreateProxyMedia", false),					disabled = not fcpxRunning },
			{ title = i18n("leaveFilesInPlaceOnImport"), 												fn = function() toggleLeaveInPlace() end, 							checked = not fcp:getPreference("FFImportCopyToMediaFolder", true),				disabled = not fcpxRunning },
			{ title = i18n("enableBackgroundRender").." ("..mod.FFAutoRenderDelay.." " .. i18n("secs", {count = tonumber(mod.FFAutoRenderDelay)}) .. ")", 					fn = function() toggleBackgroundRender() end, 						checked = fcp:getPreference("FFAutoStartBGRender", true),						disabled = not fcpxRunning },
			{ title = "-" },
		}
		local automationOptions = {
			{ title = i18n("enableScrollingTimeline"), 													fn = toggleScrollingTimeline, 										checked = scrollingTimelineActive },
			{ title = i18n("enableTimelinePlayheadLock"),												fn = toggleLockPlayhead, 											checked = lockTimelinePlayhead},
			{ title = i18n("enableShortcutsDuringFullscreen"), 											fn = toggleEnableShortcutsDuringFullscreenPlayback, 				checked = enableShortcutsDuringFullscreenPlayback },
			{ title = "-" },
			{ title = i18n("closeMediaImport"), 														fn = toggleMediaImportWatcher, 										checked = enableMediaImportWatcher },
		}
		local automationTable = {
			{ title = string.upper(i18n("automation")) .. ":", 											disabled = true },
			{ title = i18n("assignEffectsShortcuts"), 													menu = settingsEffectsShortcutsTable },
			{ title = i18n("assignTransitionsShortcuts"), 												menu = settingsTransitionsShortcutsTable },
			{ title = i18n("assignTitlesShortcuts"),													menu = settingsTitlesShortcutsTable },
			{ title = i18n("assignGeneratorsShortcuts"), 												menu = settingsGeneratorsShortcutsTable },
			{ title = i18n("options"),																	menu = automationOptions },
			{ title = "-" },
		}
		local toolsSettings = {
			{ title = i18n("enableTouchBar"), 															fn = toggleTouchBar, 												checked = displayTouchBar, 									disabled = not touchBarSupported},
			{ title = i18n("enableHacksHUD"), 															fn = toggleEnableHacksHUD, 											checked = enableHacksHUD},
			{ title = i18n("enableMobileNotifications"),												fn = toggleEnableMobileNotifications, 								checked = enableMobileNotifications},
			{ title = i18n("enableClipboardHistory"),													fn = toggleEnableClipboardHistory, 									checked = enableClipboardHistory},
			{ title = i18n("enableSharedClipboard"), 													fn = toggleEnableSharedClipboard, 									checked = enableSharedClipboard,							disabled = not enableClipboardHistory},
			{ title = i18n("enableXMLSharing"),															fn = toggleEnableXMLSharing, 										checked = enableXMLSharing},
			{ title = i18n("enableVoiceCommands"),														fn = toggleEnableVoiceCommands, 									checked = settings.get("fcpxHacks.enableVoiceCommands") },

		}
		local toolsTable = {
			{ title = string.upper(i18n("tools")) .. ":", 												disabled = true },
			{ title = i18n("importSharedXMLFile"),														menu = settingsSharedXMLTable },
			{ title = i18n("pasteFromClipboardHistory"),												menu = settingsClipboardHistoryTable },
			{ title = i18n("pasteFromSharedClipboard"), 												menu = settingsSharedClipboardTable },
			{ title = i18n("assignHUDButtons"), 														menu = settingsHUDButtons },
			{ title = i18n("options"),																	menu = toolsSettings },
			{ title = "-" },
		}
		local advancedTable = {
			{ title = i18n("enableHacksShortcuts"), 													fn = toggleEnableHacksShortcutsInFinalCutPro, 						checked = enableHacksShortcutsInFinalCutPro},
			{ title = i18n("enableTimecodeOverlay"), 													fn = toggleTimecodeOverlay, 										checked = mod.FFEnableGuards },
			{ title = i18n("enableMovingMarkers"), 														fn = toggleMovingMarkers, 											checked = mod.allowMovingMarkers },
			{ title = i18n("enableRenderingDuringPlayback"),											fn = togglePerformTasksDuringPlayback, 								checked = not mod.FFSuspendBGOpsDuringPlay },
			{ title = "-" },
			{ title = i18n("changeBackupInterval") .. " (" .. tostring(mod.FFPeriodicBackupInterval) .. " " .. i18n("mins") .. ")", fn = changeBackupInterval },
			{ title = i18n("changeSmartCollectionLabel"),												fn = changeSmartCollectionsLabel },
		}
		local hacksTable = {
			{ title = string.upper(i18n("hacks")) .. ":", 												disabled = true },
			{ title = i18n("advancedFeatures"),															menu = advancedTable },
			{ title = "-" },
		}
		local settingsTable = {
			{ title = i18n("preferences") .. "...", 													menu = settingsMenuTable },
			{ title = "-" },
			{ title = i18n("quit") .. " FCPX Hacks", 													fn = quitFCPXHacks},
		}

		--------------------------------------------------------------------------------
		-- Setup Menubar:
		--------------------------------------------------------------------------------
		if menubarShortcutsEnabled then 	menuTable = fnutils.concat(menuTable, shortcutsTable) 	end
		if menubarAutomationEnabled then	menuTable = fnutils.concat(menuTable, automationTable)	end
		if menubarToolsEnabled then 		menuTable = fnutils.concat(menuTable, toolsTable)		end
		if menubarHacksEnabled then 		menuTable = fnutils.concat(menuTable, hacksTable)		end

		menuTable = fnutils.concat(menuTable, settingsTable)

		--------------------------------------------------------------------------------
		-- Check for Updates:
		--------------------------------------------------------------------------------
		if latestScriptVersion ~= nil then
			if latestScriptVersion > fcpxhacks.scriptVersion then
				table.insert(menuTable, 1, { title = i18n("updateAvailable") .. " (" .. i18n("version") .. " " .. latestScriptVersion .. ")", fn = getScriptUpdate})
				table.insert(menuTable, 2, { title = "-" })
			end
		end

		--------------------------------------------------------------------------------
		-- Set the Menu:
		--------------------------------------------------------------------------------
		fcpxMenubar:setMenu(menuTable)

	end

	--------------------------------------------------------------------------------
	-- UPDATE MENUBAR ICON:
	--------------------------------------------------------------------------------
	function updateMenubarIcon()

		local fcpxHacksIcon = image.imageFromPath("~/.hammerspoon/hs/fcpxhacks/assets/fcpxhacks.png")
		local fcpxHacksIconSmall = fcpxHacksIcon:setSize({w=18,h=18})
		local displayMenubarAsIcon = settings.get("fcpxHacks.displayMenubarAsIcon")
		local enableProxyMenuIcon = settings.get("fcpxHacks.enableProxyMenuIcon")
		local proxyMenuIcon = ""

		local proxyStatusIcon = nil
		local FFPlayerQuality = fcp:getPreference("FFPlayerQuality")
		if FFPlayerQuality == 4 then
			proxyStatusIcon = "🔴" 		-- Proxy (4)
		else
			proxyStatusIcon = "🔵" 		-- Original (5)
		end

		fcpxMenubar:setIcon(nil)

		if enableProxyMenuIcon ~= nil then
			if enableProxyMenuIcon == true then
				if proxyStatusIcon ~= nil then
					proxyMenuIcon = " " .. proxyStatusIcon
				else
					proxyMenuIcon = ""
				end
			end
		end

		if displayMenubarAsIcon == nil then
			fcpxMenubar:setTitle("FCPX Hacks" .. proxyMenuIcon)
		else
			if displayMenubarAsIcon then
				fcpxMenubar:setIcon(fcpxHacksIconSmall)
				if proxyStatusIcon ~= nil then
					if proxyStatusIcon ~= "" then
						if enableProxyMenuIcon then
							proxyMenuIcon = proxyMenuIcon .. "  "
						end
					end
				 end
				fcpxMenubar:setTitle(proxyMenuIcon)
			else
				fcpxMenubar:setTitle("FCPX Hacks" .. proxyMenuIcon)
			end
		end

	end

--------------------------------------------------------------------------------
-- HELP:
--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- DISPLAY A LIST OF ALL SHORTCUTS:
	--------------------------------------------------------------------------------
	function displayShortcutList()

		local enableHacksShortcutsInFinalCutPro = settings.get("fcpxHacks.enableHacksShortcutsInFinalCutPro")
		if enableHacksShortcutsInFinalCutPro == nil then enableHacksShortcutsInFinalCutPro = false end

		if enableHacksShortcutsInFinalCutPro then
			if fcp:isRunning() then
				fcp:launch()
				fcp:commandEditor():show()
			end
		else
			local whatMessage = [[The default FCPX Hacks Shortcut Keys are:

	---------------------------------
	CONTROL+OPTION+COMMAND:
	---------------------------------
	L = Launch Final Cut Pro (System Wide)

	A = Toggle HUD
	Z = Toggle Touch Bar

	W = Toggle Scrolling Timeline

	H = Highlight Browser Playhead
	F = Reveal in Browser & Highlight
	S = Single Match Frame & Highlight

	D = Reveal Multicam in Browser & Highlight
	G = Reveal Multicam in Angle Editor & Highlight

	E = Batch Export from Browser

	B = Change Backup Interval

	T = Toggle Timecode Overlays
	Y = Toggle Moving Markers
	P = Toggle Rendering During Playback

	M = Select Color Board Puck 1
	, = Select Color Board Puck 2
	. = Select Color Board Puck 3
	/ = Select Color Board Puck 4

	1-9 = Restore Keyword Preset

	+ = Increase Timeline Clip Height
	- = Decrease Timeline Clip Height

	Left Arrow = Select All Clips to Left
	Right Arrow = Select All Clips to Right

	-----------------------------------------
	CONTROL+OPTION+COMMAND+SHIFT:
	-----------------------------------------
	1-9 = Save Keyword Preset

	-----------------------------------------
	CONTROL+SHIFT:
	-----------------------------------------
	1-5 = Apply Effect]]

			dialog.displayMessage(whatMessage)
		end
	end

--------------------------------------------------------------------------------
-- UPDATE EFFECTS/TRANSITIONS/TITLES/GENERATORS LISTS:
--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- GET LIST OF EFFECTS:
	--------------------------------------------------------------------------------
	function updateEffectsList()

		--------------------------------------------------------------------------------
		-- Make sure Final Cut Pro is active:
		--------------------------------------------------------------------------------
		fcp:launch()

		--------------------------------------------------------------------------------
		-- Warning message:
		--------------------------------------------------------------------------------
		dialog.displayMessage(i18n("updateEffectsListWarning"))

		--------------------------------------------------------------------------------
		-- Save the layout of the Transitions panel in case we switch away...
		--------------------------------------------------------------------------------
		local transitions = fcp:transitions()
		local transitionsLayout = transitions:saveLayout()

		--------------------------------------------------------------------------------
		-- Make sure Effects panel is open:
		--------------------------------------------------------------------------------
		local effects = fcp:effects()
		local effectsShowing = effects:isShowing()
		if not effects:show():isShowing() then
			dialog.displayErrorMessage("Unable to activate the Effects panel.\n\nError occurred in updateEffectsList().")
			showTouchbar()
			return "Fail"
		end

		local effectsLayout = effects:saveLayout()

		--------------------------------------------------------------------------------
		-- Make sure "Installed Effects" is selected:
		--------------------------------------------------------------------------------
		effects:showInstalledEffects()

		--------------------------------------------------------------------------------
		-- Make sure there's nothing in the search box:
		--------------------------------------------------------------------------------
		effects:search():clear()

		local sidebar = effects:sidebar()

		--------------------------------------------------------------------------------
		-- Ensure the sidebar is visible
		--------------------------------------------------------------------------------
		effects:showSidebar()

		--------------------------------------------------------------------------------
		-- If it's still invisible, we have a problem.
		--------------------------------------------------------------------------------
		if not sidebar:isShowing() then
			dialog.displayErrorMessage("Unable to activate the Effects sidebar.\n\nError occurred in updateEffectsList().")
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Click 'All Video':
		--------------------------------------------------------------------------------
		if not effects:showAllVideoEffects() then
			dialog.displayErrorMessage("Unable to select all video effects.\n\nError occurred in updateEffectsList().")
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Get list of All Video Effects:
		--------------------------------------------------------------------------------
		local allVideoEffects = effects:getCurrentTitles()
		if not allVideoEffects then
			dialog.displayErrorMessage("Unable to get list of all effects.\n\nError occurred in updateEffectsList().")
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Click 'All Audio':
		--------------------------------------------------------------------------------
		if not effects:showAllAudioEffects() then
			dialog.displayErrorMessage("Unable to select all audio effects.\n\nError occurred in updateEffectsList().")
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Get list of All Audio Effects:
		--------------------------------------------------------------------------------
		local allAudioEffects = effects:getCurrentTitles()
		if not allAudioEffects then
			dialog.displayErrorMessage("Unable to get list of all effects.\n\nError occurred in updateEffectsList().")
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Restore Effects and Transitions Panels:
		--------------------------------------------------------------------------------
		effects:loadLayout(effectsLayout)
		transitions:loadLayout(transitionsLayout)
		if not effectsShowing then effects:hide() end

		--------------------------------------------------------------------------------
		-- All done!
		--------------------------------------------------------------------------------
		if #allVideoEffects == 0 or #allAudioEffects == 0 then
			dialog.displayMessage(i18n("updateEffectsListFailed") .. "\n\n" .. i18n("pleaseTryAgain"))
			return "Fail"
		else
			--------------------------------------------------------------------------------
			-- Save Results to Settings:
			--------------------------------------------------------------------------------
			local currentLanguage = fcp:getCurrentLanguage()
			settings.set("fcpxHacks." .. currentLanguage .. ".allVideoEffects", allVideoEffects)
			settings.set("fcpxHacks." .. currentLanguage .. ".allAudioEffects", allAudioEffects)
			settings.set("fcpxHacks." .. currentLanguage .. ".effectsListUpdated", true)

			--------------------------------------------------------------------------------
			-- Update Chooser:
			--------------------------------------------------------------------------------
			hacksconsole.refresh()

			--------------------------------------------------------------------------------
			-- Refresh Menubar:
			--------------------------------------------------------------------------------
			refreshMenuBar()

			--------------------------------------------------------------------------------
			-- Let the user know everything's good:
			--------------------------------------------------------------------------------
			dialog.displayMessage(i18n("updateEffectsListDone"))
		end

	end

	--------------------------------------------------------------------------------
	-- GET LIST OF TRANSITIONS:
	--------------------------------------------------------------------------------
	function updateTransitionsList()

		--------------------------------------------------------------------------------
		-- Make sure Final Cut Pro is active:
		--------------------------------------------------------------------------------
		fcp:launch()

		--------------------------------------------------------------------------------
		-- Warning message:
		--------------------------------------------------------------------------------
		dialog.displayMessage(i18n("updateTransitionsListWarning"))

		--------------------------------------------------------------------------------
		-- Save the layout of the Effects panel, in case we switch away...
		--------------------------------------------------------------------------------
		local effects = fcp:effects()
		local effectsLayout = nil
		if effects:isShowing() then
			effectsLayout = effects:saveLayout()
		end

		--------------------------------------------------------------------------------
		-- Make sure Transitions panel is open:
		--------------------------------------------------------------------------------
		local transitions = fcp:transitions()
		local transitionsShowing = transitions:isShowing()
		if not transitions:show():isShowing() then
			dialog.displayErrorMessage("Unable to activate the Transitions panel.\n\nError occurred in updateEffectsList().")
			return "Fail"
		end

		local transitionsLayout = transitions:saveLayout()

		--------------------------------------------------------------------------------
		-- Make sure "Installed Transitions" is selected:
		--------------------------------------------------------------------------------
		transitions:showInstalledTransitions()

		--------------------------------------------------------------------------------
		-- Make sure there's nothing in the search box:
		--------------------------------------------------------------------------------
		transitions:search():clear()

		--------------------------------------------------------------------------------
		-- Make sure the sidebar is visible:
		--------------------------------------------------------------------------------
		local sidebar = transitions:sidebar()

		transitions:showSidebar()

		if not sidebar:isShowing() then
			dialog.displayErrorMessage("Unable to activate the Transitions sidebar.\n\nError occurred in updateTransitionsList().")
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Click 'All' in the sidebar:
		--------------------------------------------------------------------------------
		transitions:showAllTransitions()

		--------------------------------------------------------------------------------
		-- Get list of All Transitions:
		--------------------------------------------------------------------------------
		local allTransitions = transitions:getCurrentTitles()
		if allTransitions == nil then
			dialog.displayErrorMessage("Unable to get list of all transitions.\n\nError occurred in updateTransitionsList().")
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Restore Effects and Transitions Panels:
		--------------------------------------------------------------------------------
		transitions:loadLayout(transitionsLayout)
		if effectsLayout then effects:loadLayout(effectsLayout) end
		if not transitionsShowing then transitions:hide() end

		--------------------------------------------------------------------------------
		-- Save Results to Settings:
		--------------------------------------------------------------------------------
		local currentLanguage = fcp:getCurrentLanguage()
		settings.set("fcpxHacks." .. currentLanguage .. ".allTransitions", allTransitions)
		settings.set("fcpxHacks." .. currentLanguage .. ".transitionsListUpdated", true)

		--------------------------------------------------------------------------------
		-- Update Chooser:
		--------------------------------------------------------------------------------
		hacksconsole.refresh()

		--------------------------------------------------------------------------------
		-- Refresh Menubar:
		--------------------------------------------------------------------------------
		refreshMenuBar()

		--------------------------------------------------------------------------------
		-- Let the user know everything's good:
		--------------------------------------------------------------------------------
		dialog.displayMessage(i18n("updateTransitionsListDone"))

	end

	--------------------------------------------------------------------------------
	-- GET LIST OF TITLES:
	--------------------------------------------------------------------------------
	function updateTitlesList()

		--------------------------------------------------------------------------------
		-- Make sure Final Cut Pro is active:
		--------------------------------------------------------------------------------
		fcp:launch()

		--------------------------------------------------------------------------------
		-- Hide the Touch Bar:
		--------------------------------------------------------------------------------
		hideTouchbar()

		--------------------------------------------------------------------------------
		-- Warning message:
		--------------------------------------------------------------------------------
		dialog.displayMessage(i18n("updateTitlesListWarning"))

		local app = fcp
		local generators = app:generators()

		local browserLayout = app:browser():saveLayout()

		--------------------------------------------------------------------------------
		-- Make sure Titles and Generators panel is open:
		--------------------------------------------------------------------------------
		if not generators:show():isShowing() then
			dialog.displayErrorMessage("Unable to activate the Titles and Generators panel.\n\nError occurred in updateEffectsList().")
			showTouchbar()
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Make sure there's nothing in the search box:
		--------------------------------------------------------------------------------
		generators:search():clear()

		--------------------------------------------------------------------------------
		-- Click 'Titles':
		--------------------------------------------------------------------------------
		generators:showAllTitles()

		--------------------------------------------------------------------------------
		-- Make sure "Installed Titles" is selected:
		--------------------------------------------------------------------------------
		generators:group():selectItem(1)

		--------------------------------------------------------------------------------
		-- Get list of All Transitions:
		--------------------------------------------------------------------------------
		local effectsList = generators:contents():childrenUI()
		local allTitles = {}
		if effectsList ~= nil then
			for i=1, #effectsList do
				allTitles[i] = effectsList[i]:attributeValue("AXTitle")
			end
		else
			dialog.displayErrorMessage("Unable to get list of all titles.\n\nError occurred in updateTitlesList().")
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Restore Effects or Transitions Panel:
		--------------------------------------------------------------------------------
		app:browser():loadLayout(browserLayout)

		showTouchbar()

		--------------------------------------------------------------------------------
		-- Save Results to Settings:
		--------------------------------------------------------------------------------
		local currentLanguage = fcp:getCurrentLanguage()
		settings.set("fcpxHacks." .. currentLanguage .. ".allTitles", allTitles)
		settings.set("fcpxHacks." .. currentLanguage .. ".titlesListUpdated", true)

		--------------------------------------------------------------------------------
		-- Update Chooser:
		--------------------------------------------------------------------------------
		hacksconsole.refresh()

		--------------------------------------------------------------------------------
		-- Refresh Menubar:
		--------------------------------------------------------------------------------
		refreshMenuBar()

		--------------------------------------------------------------------------------
		-- Let the user know everything's good:
		--------------------------------------------------------------------------------
		dialog.displayMessage(i18n("updateTitlesListDone"))

	end

	--------------------------------------------------------------------------------
	-- GET LIST OF GENERATORS:
	--------------------------------------------------------------------------------
	function updateGeneratorsList()

		--------------------------------------------------------------------------------
		-- Make sure Final Cut Pro is active:
		--------------------------------------------------------------------------------
		fcp:launch()

		--------------------------------------------------------------------------------
		-- Hide the Touch Bar:
		--------------------------------------------------------------------------------
		hideTouchbar()

		--------------------------------------------------------------------------------
		-- Warning message:
		--------------------------------------------------------------------------------
		dialog.displayMessage(i18n("updateGeneratorsListWarning"))

		local app = fcp
		local generators = app:generators()

		local browserLayout = app:browser():saveLayout()

		--------------------------------------------------------------------------------
		-- Make sure Titles and Generators panel is open:
		--------------------------------------------------------------------------------
		if not generators:show():isShowing() then
			dialog.displayErrorMessage("Unable to activate the Titles and Generators panel.\n\nError occurred in updateEffectsList().")
			showTouchbar()
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Make sure there's nothing in the search box:
		--------------------------------------------------------------------------------
		generators:search():clear()

		--------------------------------------------------------------------------------
		-- Click 'Generators':
		--------------------------------------------------------------------------------
		generators:showAllGenerators()

		--------------------------------------------------------------------------------
		-- Make sure "Installed Titles" is selected:
		--------------------------------------------------------------------------------
		generators:group():selectItem(1)

		--------------------------------------------------------------------------------
		-- Get list of All Transitions:
		--------------------------------------------------------------------------------
		local effectsList = generators:contents():childrenUI()
		local allGenerators = {}
		if effectsList ~= nil then
			for i=1, #effectsList do
				allGenerators[i] = effectsList[i]:attributeValue("AXTitle")
			end
		else
			dialog.displayErrorMessage("Unable to get list of all Generators.\n\nError occurred in updateGeneratorsList().")
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Restore Effects or Transitions Panel:
		--------------------------------------------------------------------------------
		app:browser():loadLayout(browserLayout)

		--------------------------------------------------------------------------------
		-- Save Results to Settings:
		--------------------------------------------------------------------------------
		local currentLanguage = fcp:getCurrentLanguage()
		settings.set("fcpxHacks." .. currentLanguage .. ".allGenerators", allGenerators)
		settings.set("fcpxHacks." .. currentLanguage .. ".generatorsListUpdated", true)

		--------------------------------------------------------------------------------
		-- Update Chooser:
		--------------------------------------------------------------------------------
		hacksconsole.refresh()

		--------------------------------------------------------------------------------
		-- Refresh Menubar:
		--------------------------------------------------------------------------------
		refreshMenuBar()

		--------------------------------------------------------------------------------
		-- Let the user know everything's good:
		--------------------------------------------------------------------------------
		dialog.displayMessage(i18n("updateGeneratorsListDone"))

	end

--------------------------------------------------------------------------------
-- ASSIGN EFFECTS/TRANSITIONS/TITLES/GENERATORS SHORTCUTS:
--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- ASSIGN EFFECTS SHORTCUT:
	--------------------------------------------------------------------------------
	function assignEffectsShortcut(whichShortcut)

		--------------------------------------------------------------------------------
		-- Was Final Cut Pro Open?
		--------------------------------------------------------------------------------
		mod.wasFinalCutProOpen = fcp:isFrontmost()

		--------------------------------------------------------------------------------
		-- Get settings:
		--------------------------------------------------------------------------------
		local currentLanguage = fcp:getCurrentLanguage()
		local effectsListUpdated 	= settings.get("fcpxHacks." .. currentLanguage .. ".effectsListUpdated")
		local allVideoEffects 		= settings.get("fcpxHacks." .. currentLanguage .. ".allVideoEffects")
		local allAudioEffects 		= settings.get("fcpxHacks." .. currentLanguage .. ".allAudioEffects")

		--------------------------------------------------------------------------------
		-- Error Checking:
		--------------------------------------------------------------------------------
		if not effectsListUpdated then
			dialog.displayMessage(i18n("assignEffectsShortcutError"))
			return "Failed"
		end
		if allVideoEffects == nil or allAudioEffects == nil then
			dialog.displayMessage(i18n("assignEffectsShortcutError"))
			return "Failed"
		end
		if next(allVideoEffects) == nil or next(allAudioEffects) == nil then
			dialog.displayMessage(i18n("assignEffectsShortcutError"))
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Video Effects List:
		--------------------------------------------------------------------------------
		local effectChooserChoices = {}
		if allVideoEffects ~= nil and next(allVideoEffects) ~= nil then
			for i=1, #allVideoEffects do
				individualEffect = {
					["text"] = allVideoEffects[i],
					["subText"] = "Video Effect",
					["function"] = "effectsShortcut",
					["function1"] = allVideoEffects[i],
					["function2"] = "",
					["function3"] = "",
					["whichShortcut"] = whichShortcut,
				}
				table.insert(effectChooserChoices, 1, individualEffect)
			end
		end

		--------------------------------------------------------------------------------
		-- Audio Effects List:
		--------------------------------------------------------------------------------
		if allAudioEffects ~= nil and next(allAudioEffects) ~= nil then
			for i=1, #allAudioEffects do
				individualEffect = {
					["text"] = allAudioEffects[i],
					["subText"] = "Audio Effect",
					["function"] = "effectsShortcut",
					["function1"] = allAudioEffects[i],
					["function2"] = "",
					["function3"] = "",
					["whichShortcut"] = whichShortcut,
				}
				table.insert(effectChooserChoices, 1, individualEffect)
			end
		end

		--------------------------------------------------------------------------------
		-- Sort everything:
		--------------------------------------------------------------------------------
		table.sort(effectChooserChoices, function(a, b) return a.text < b.text end)

		--------------------------------------------------------------------------------
		-- Setup Chooser:
		--------------------------------------------------------------------------------
		effectChooser = chooser.new(effectChooserAction):bgDark(true)
														:choices(effectChooserChoices)

		--------------------------------------------------------------------------------
		-- Allow for Reduce Transparency:
		--------------------------------------------------------------------------------
		if screen.accessibilitySettings()["ReduceTransparency"] then
			effectChooser:fgColor(nil)
						 :subTextColor(nil)
		else
			effectChooser:fgColor(drawing.color.x11.snow)
		 				 :subTextColor(drawing.color.x11.snow)
		end

		--------------------------------------------------------------------------------
		-- Show Chooser:
		--------------------------------------------------------------------------------
		effectChooser:show()

	end

		--------------------------------------------------------------------------------
		-- ASSIGN EFFECTS SHORTCUT CHOOSER ACTION:
		--------------------------------------------------------------------------------
		function effectChooserAction(result)

			--------------------------------------------------------------------------------
			-- Hide Chooser:
			--------------------------------------------------------------------------------
			effectChooser:hide()

			--------------------------------------------------------------------------------
			-- Perform Specific Function:
			--------------------------------------------------------------------------------
			if result ~= nil then
				--------------------------------------------------------------------------------
				-- Save the selection:
				--------------------------------------------------------------------------------
				whichShortcut = result["whichShortcut"]
				local currentLanguage = fcp:getCurrentLanguage()
				if whichShortcut == 1 then settings.set("fcpxHacks." .. currentLanguage .. ".effectsShortcutOne", 		result["text"]) end
				if whichShortcut == 2 then settings.set("fcpxHacks." .. currentLanguage .. ".effectsShortcutTwo", 		result["text"]) end
				if whichShortcut == 3 then settings.set("fcpxHacks." .. currentLanguage .. ".effectsShortcutThree", 	result["text"]) end
				if whichShortcut == 4 then settings.set("fcpxHacks." .. currentLanguage .. ".effectsShortcutFour", 	result["text"]) end
				if whichShortcut == 5 then settings.set("fcpxHacks." .. currentLanguage .. ".effectsShortcutFive", 	result["text"]) end
			end

			--------------------------------------------------------------------------------
			-- Put focus back in Final Cut Pro:
			--------------------------------------------------------------------------------
			if mod.wasFinalCutProOpen then fcp:launch() end

			--------------------------------------------------------------------------------
			-- Refresh Menubar:
			--------------------------------------------------------------------------------
			refreshMenuBar()

		end

	--------------------------------------------------------------------------------
	-- ASSIGN TRANSITIONS SHORTCUT:
	--------------------------------------------------------------------------------
	function assignTransitionsShortcut(whichShortcut)

		--------------------------------------------------------------------------------
		-- Was Final Cut Pro Open?
		--------------------------------------------------------------------------------
		mod.wasFinalCutProOpen = fcp:isFrontmost()

		--------------------------------------------------------------------------------
		-- Get settings:
		--------------------------------------------------------------------------------
		local currentLanguage = fcp:getCurrentLanguage()
		local transitionsListUpdated = settings.get("fcpxHacks." .. currentLanguage .. ".transitionsListUpdated")
		local allTransitions = settings.get("fcpxHacks." .. currentLanguage .. ".allTransitions")

		--------------------------------------------------------------------------------
		-- Error Checking:
		--------------------------------------------------------------------------------
		if not transitionsListUpdated then
			dialog.displayMessage(i18n("assignTransitionsShortcutError"))
			return "Failed"
		end
		if allTransitions == nil then
			dialog.displayMessage(i18n("assignTransitionsShortcutError"))
			return "Failed"
		end
		if next(allTransitions) == nil then
			dialog.displayMessage(i18n("assignTransitionsShortcutError"))
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Video Effects List:
		--------------------------------------------------------------------------------
		local transitionChooserChoices = {}
		if allTransitions ~= nil and next(allTransitions) ~= nil then
			for i=1, #allTransitions do
				individualEffect = {
					["text"] = allTransitions[i],
					["subText"] = "Transition",
					["function"] = "transitionsShortcut",
					["function1"] = allTransitions[i],
					["function2"] = "",
					["function3"] = "",
					["whichShortcut"] = whichShortcut,
				}
				table.insert(transitionChooserChoices, 1, individualEffect)
			end
		end

		--------------------------------------------------------------------------------
		-- Sort everything:
		--------------------------------------------------------------------------------
		table.sort(transitionChooserChoices, function(a, b) return a.text < b.text end)

		--------------------------------------------------------------------------------
		-- Setup Chooser:
		--------------------------------------------------------------------------------
		transitionChooser = chooser.new(transitionsChooserAction):bgDark(true)
																 :choices(transitionChooserChoices)

		--------------------------------------------------------------------------------
		-- Allow for Reduce Transparency:
		--------------------------------------------------------------------------------
		if screen.accessibilitySettings()["ReduceTransparency"] then
			transitionChooser:fgColor(nil)
							 :subTextColor(nil)
		else
			transitionChooser:fgColor(drawing.color.x11.snow)
							 :subTextColor(drawing.color.x11.snow)
		end

		--------------------------------------------------------------------------------
		-- Show Chooser:
		--------------------------------------------------------------------------------
		transitionChooser:show()

	end

		--------------------------------------------------------------------------------
		-- ASSIGN EFFECTS SHORTCUT CHOOSER ACTION:
		--------------------------------------------------------------------------------
		function transitionsChooserAction(result)

			--------------------------------------------------------------------------------
			-- Hide Chooser:
			--------------------------------------------------------------------------------
			transitionChooser:hide()

			--------------------------------------------------------------------------------
			-- Perform Specific Function:
			--------------------------------------------------------------------------------
			if result ~= nil then
				--------------------------------------------------------------------------------
				-- Save the selection:
				--------------------------------------------------------------------------------
				whichShortcut = result["whichShortcut"]
				local currentLanguage = fcp:getCurrentLanguage()
				if whichShortcut == 1 then settings.set("fcpxHacks." .. currentLanguage .. ".transitionsShortcutOne", 	result["text"]) end
				if whichShortcut == 2 then settings.set("fcpxHacks." .. currentLanguage .. ".transitionsShortcutTwo", 	result["text"]) end
				if whichShortcut == 3 then settings.set("fcpxHacks." .. currentLanguage .. ".transitionsShortcutThree", 	result["text"]) end
				if whichShortcut == 4 then settings.set("fcpxHacks." .. currentLanguage .. ".transitionsShortcutFour", 	result["text"]) end
				if whichShortcut == 5 then settings.set("fcpxHacks." .. currentLanguage .. ".transitionsShortcutFive", 	result["text"]) end
			end

			--------------------------------------------------------------------------------
			-- Put focus back in Final Cut Pro:
			--------------------------------------------------------------------------------
			if mod.wasFinalCutProOpen then fcp:launch() end

			--------------------------------------------------------------------------------
			-- Refresh Menubar:
			--------------------------------------------------------------------------------
			refreshMenuBar()

		end

	--------------------------------------------------------------------------------
	-- ASSIGN TITLES SHORTCUT:
	--------------------------------------------------------------------------------
	function assignTitlesShortcut(whichShortcut)

		--------------------------------------------------------------------------------
		-- Was Final Cut Pro Open?
		--------------------------------------------------------------------------------
		mod.wasFinalCutProOpen = fcp:isFrontmost()

		--------------------------------------------------------------------------------
		-- Get settings:
		--------------------------------------------------------------------------------
		local currentLanguage = fcp:getCurrentLanguage()
		local titlesListUpdated = settings.get("fcpxHacks." .. currentLanguage .. ".titlesListUpdated")
		local allTitles = settings.get("fcpxHacks." .. currentLanguage .. ".allTitles")

		--------------------------------------------------------------------------------
		-- Error Checking:
		--------------------------------------------------------------------------------
		if not titlesListUpdated then
			dialog.displayMessage(i18n("assignTitlesShortcutError"))
			return "Failed"
		end
		if allTitles == nil then
			dialog.displayMessage(i18n("assignTitlesShortcutError"))
			return "Failed"
		end
		if next(allTitles) == nil then
			dialog.displayMessage(i18n("assignTitlesShortcutError"))
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Titles List:
		--------------------------------------------------------------------------------
		local titlesChooserChoices = {}
		if allTitles ~= nil and next(allTitles) ~= nil then
			for i=1, #allTitles do
				individualEffect = {
					["text"] = allTitles[i],
					["subText"] = "Title",
					["function"] = "transitionsShortcut",
					["function1"] = allTitles[i],
					["function2"] = "",
					["function3"] = "",
					["whichShortcut"] = whichShortcut,
				}
				table.insert(titlesChooserChoices, 1, individualEffect)
			end
		end

		--------------------------------------------------------------------------------
		-- Sort everything:
		--------------------------------------------------------------------------------
		table.sort(titlesChooserChoices, function(a, b) return a.text < b.text end)

		--------------------------------------------------------------------------------
		-- Setup Chooser:
		--------------------------------------------------------------------------------
		titlesChooser = chooser.new(titlesChooserAction):bgDark(true)
														:choices(titlesChooserChoices)

		--------------------------------------------------------------------------------
		-- Allow for Reduce Transparency:
		--------------------------------------------------------------------------------
		if screen.accessibilitySettings()["ReduceTransparency"] then
			titlesChooser:fgColor(nil)
						 :subTextColor(nil)
		else
			titlesChooser:fgColor(drawing.color.x11.snow)
						 :subTextColor(drawing.color.x11.snow)
		end

		--------------------------------------------------------------------------------
		-- Show Chooser:
		--------------------------------------------------------------------------------
		titlesChooser:show()

	end

		--------------------------------------------------------------------------------
		-- ASSIGN TITLES SHORTCUT CHOOSER ACTION:
		--------------------------------------------------------------------------------
		function titlesChooserAction(result)

			--------------------------------------------------------------------------------
			-- Hide Chooser:
			--------------------------------------------------------------------------------
			titlesChooser:hide()

			--------------------------------------------------------------------------------
			-- Perform Specific Function:
			--------------------------------------------------------------------------------
			if result ~= nil then
				--------------------------------------------------------------------------------
				-- Save the selection:
				--------------------------------------------------------------------------------
				whichShortcut = result["whichShortcut"]
				local currentLanguage = fcp:getCurrentLanguage()
				if whichShortcut == 1 then settings.set("fcpxHacks." .. currentLanguage .. ".titlesShortcutOne", 		result["text"]) end
				if whichShortcut == 2 then settings.set("fcpxHacks." .. currentLanguage .. ".titlesShortcutTwo", 		result["text"]) end
				if whichShortcut == 3 then settings.set("fcpxHacks." .. currentLanguage .. ".titlesShortcutThree", 	result["text"]) end
				if whichShortcut == 4 then settings.set("fcpxHacks." .. currentLanguage .. ".titlesShortcutFour", 		result["text"]) end
				if whichShortcut == 5 then settings.set("fcpxHacks." .. currentLanguage .. ".titlesShortcutFive", 		result["text"]) end
			end

			--------------------------------------------------------------------------------
			-- Put focus back in Final Cut Pro:
			--------------------------------------------------------------------------------
			if mod.wasFinalCutProOpen then fcp:launch() end

			--------------------------------------------------------------------------------
			-- Refresh Menubar:
			--------------------------------------------------------------------------------
			refreshMenuBar()

		end

	--------------------------------------------------------------------------------
	-- ASSIGN GENERATORS SHORTCUT:
	--------------------------------------------------------------------------------
	function assignGeneratorsShortcut(whichShortcut)

		--------------------------------------------------------------------------------
		-- Was Final Cut Pro Open?
		--------------------------------------------------------------------------------
		mod.wasFinalCutProOpen = fcp:isFrontmost()

		--------------------------------------------------------------------------------
		-- Get settings:
		--------------------------------------------------------------------------------
		local currentLanguage = fcp:getCurrentLanguage()
		local generatorsListUpdated = settings.get("fcpxHacks." .. currentLanguage .. ".generatorsListUpdated")
		local allGenerators = settings.get("fcpxHacks." .. currentLanguage .. ".allGenerators")

		--------------------------------------------------------------------------------
		-- Error Checking:
		--------------------------------------------------------------------------------
		if not generatorsListUpdated then
			dialog.displayMessage(i18n("assignGeneratorsShortcutError"))
			return "Failed"
		end
		if allGenerators == nil then
			dialog.displayMessage(i18n("assignGeneratorsShortcutError"))
			return "Failed"
		end
		if next(allGenerators) == nil then
			dialog.displayMessage(i18n("assignGeneratorsShortcutError"))
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Generators List:
		--------------------------------------------------------------------------------
		local generatorsChooserChoices = {}
		if allGenerators ~= nil and next(allGenerators) ~= nil then
			for i=1, #allGenerators do
				individualEffect = {
					["text"] = allGenerators[i],
					["subText"] = "Generator",
					["function"] = "transitionsShortcut",
					["function1"] = allGenerators[i],
					["function2"] = "",
					["function3"] = "",
					["whichShortcut"] = whichShortcut,
				}
				table.insert(generatorsChooserChoices, 1, individualEffect)
			end
		end

		--------------------------------------------------------------------------------
		-- Sort everything:
		--------------------------------------------------------------------------------
		table.sort(generatorsChooserChoices, function(a, b) return a.text < b.text end)

		--------------------------------------------------------------------------------
		-- Setup Chooser:
		--------------------------------------------------------------------------------
		generatorsChooser = chooser.new(generatorsChooserAction):bgDark(true)
																:choices(generatorsChooserChoices)

		--------------------------------------------------------------------------------
		-- Allow for Reduce Transparency:
		--------------------------------------------------------------------------------
		if screen.accessibilitySettings()["ReduceTransparency"] then
			generatorsChooser:fgColor(nil)
							 :subTextColor(nil)
		else
			generatorsChooser:fgColor(drawing.color.x11.snow)
							 :subTextColor(drawing.color.x11.snow)
		end

		--------------------------------------------------------------------------------
		-- Show Chooser:
		--------------------------------------------------------------------------------
		generatorsChooser:show()

	end

		--------------------------------------------------------------------------------
		-- ASSIGN GENERATORS SHORTCUT CHOOSER ACTION:
		--------------------------------------------------------------------------------
		function generatorsChooserAction(result)

			--------------------------------------------------------------------------------
			-- Hide Chooser:
			--------------------------------------------------------------------------------
			generatorsChooser:hide()

			--------------------------------------------------------------------------------
			-- Perform Specific Function:
			--------------------------------------------------------------------------------
			if result ~= nil then
				--------------------------------------------------------------------------------
				-- Save the selection:
				--------------------------------------------------------------------------------
				whichShortcut = result["whichShortcut"]
				local currentLanguage = fcp:getCurrentLanguage()
				if whichShortcut == 1 then settings.set("fcpxHacks." .. currentLanguage .. ".generatorsShortcutOne", 		result["text"]) end
				if whichShortcut == 2 then settings.set("fcpxHacks." .. currentLanguage .. ".generatorsShortcutTwo", 		result["text"]) end
				if whichShortcut == 3 then settings.set("fcpxHacks." .. currentLanguage .. ".generatorsShortcutThree", 	result["text"]) end
				if whichShortcut == 4 then settings.set("fcpxHacks." .. currentLanguage .. ".generatorsShortcutFour", 		result["text"]) end
				if whichShortcut == 5 then settings.set("fcpxHacks." .. currentLanguage .. ".generatorsShortcutFive", 		result["text"]) end
			end

			--------------------------------------------------------------------------------
			-- Put focus back in Final Cut Pro:
			--------------------------------------------------------------------------------
			if mod.wasFinalCutProOpen then fcp:launch() end

			--------------------------------------------------------------------------------
			-- Refresh Menubar:
			--------------------------------------------------------------------------------
			refreshMenuBar()

		end

--------------------------------------------------------------------------------
-- CHANGE:
--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- CHANGE HIGHLIGHT PLAYHEAD TIME:
	--------------------------------------------------------------------------------
	function changeHighlightPlayheadTime(value)
		settings.set("fcpxHacks.highlightPlayheadTime", value)
		refreshMenuBar()
	end

	--------------------------------------------------------------------------------
	-- CHANGE BATCH EXPORT DESTINATION PRESET:
	--------------------------------------------------------------------------------
	function changeBatchExportDestinationPreset()
		local shareMenuItems = fcp:menuBar():findMenuItemsUI("File", "Share")
		if not shareMenuItems then
			dialog.displayErrorMessage(i18n("batchExportDestinationsNotFound"))
			return
		end

		local destinations = {}

		for i = 1, #shareMenuItems-2 do
			local item = shareMenuItems[i]
			local title = item:attributeValue("AXTitle")
			if title ~= nil then
				local value = string.sub(title, 1, -4)
				if item:attributeValue("AXMenuItemCmdChar") then -- it's the default
					-- Remove (default) text:
					local firstBracket = string.find(value, " %(", 1)
					if firstBracket == nil then
						firstBracket = string.find(value, "（", 1)
					end
					value = string.sub(value, 1, firstBracket - 1)
				end
				destinations[#destinations + 1] = value
			end
		end

		local batchExportDestinationPreset = settings.get("fcpxHacks.batchExportDestinationPreset")
		local defaultItems = {}
		if batchExportDestinationPreset ~= nil then defaultItems[1] = batchExportDestinationPreset end

		local result = dialog.displayChooseFromList(i18n("selectDestinationPreset"), destinations, defaultItems)
		if result and #result > 0 then
			settings.set("fcpxHacks.batchExportDestinationPreset", result[1])
		end
	end

	--------------------------------------------------------------------------------
	-- CHANGE BATCH EXPORT DESTINATION FOLDER:
	--------------------------------------------------------------------------------
	function changeBatchExportDestinationFolder()
		local result = dialog.displayChooseFolder(i18n("selectDestinationFolder"))
		if result == false then return end

		settings.set("fcpxHacks.batchExportDestinationFolder", result)
	end

	--------------------------------------------------------------------------------
	-- CHANGE FINAL CUT PRO LANGUAGE:
	--------------------------------------------------------------------------------
	function changeFinalCutProLanguage(language)

		--------------------------------------------------------------------------------
		-- If Final Cut Pro is running...
		--------------------------------------------------------------------------------
		local restartStatus = false
		if fcp:isRunning() then
			if dialog.displayYesNoQuestion(i18n("changeFinalCutProLanguage") .. "\n\n" .. i18n("doYouWantToContinue")) then
				restartStatus = true
			else
				return "Done"
			end
		end

		--------------------------------------------------------------------------------
		-- Update Final Cut Pro's settings::
		--------------------------------------------------------------------------------
		local result = fcp:setPreference("AppleLanguages", {language})
		if not result then
			dialog.displayErrorMessage(i18n("failedToChangeLanguage"))
		end

		--------------------------------------------------------------------------------
		-- Change FCPX Hacks Language:
		--------------------------------------------------------------------------------
		fcp:getCurrentLanguage(true, language)

		--------------------------------------------------------------------------------
		-- Restart Final Cut Pro:
		--------------------------------------------------------------------------------
		if restartStatus then
			if not fcp:restart() then
				--------------------------------------------------------------------------------
				-- Failed to restart Final Cut Pro:
				--------------------------------------------------------------------------------
				dialog.displayErrorMessage(i18n("failedToRestart"))
				return "Failed"
			end
		end

	end

	--------------------------------------------------------------------------------
	-- CHANGE TOUCH BAR LOCATION:
	--------------------------------------------------------------------------------
	function changeTouchBarLocation(value)
		settings.set("fcpxHacks.displayTouchBarLocation", value)

		if touchBarSupported then
			local displayTouchBar = settings.get("fcpxHacks.displayTouchBar") or false
			if displayTouchBar then setTouchBarLocation() end
		end

		refreshMenuBar()
	end

	--------------------------------------------------------------------------------
	-- CHANGE HIGHLIGHT SHAPE:
	--------------------------------------------------------------------------------
	function changeHighlightShape(value)
		settings.set("fcpxHacks.displayHighlightShape", value)
		refreshMenuBar()
	end

	--------------------------------------------------------------------------------
	-- CHANGE HIGHLIGHT COLOUR:
	--------------------------------------------------------------------------------
	function changeHighlightColour(value)
		if value=="Custom" then
			local displayHighlightCustomColour = settings.get("fcpxHacks.displayHighlightCustomColour") or nil
			local result = dialog.displayColorPicker(displayHighlightCustomColour)
			if result == nil then return nil end
			settings.set("fcpxHacks.displayHighlightCustomColour", result)
		end
		settings.set("fcpxHacks.displayHighlightColour", value)
		refreshMenuBar()
	end

	--------------------------------------------------------------------------------
	-- FCPX CHANGE BACKUP INTERVAL:
	--------------------------------------------------------------------------------
	function changeBackupInterval()

		--------------------------------------------------------------------------------
		-- Delete any pre-existing highlights:
		--------------------------------------------------------------------------------
		deleteAllHighlights()

		--------------------------------------------------------------------------------
		-- Get existing value:
		--------------------------------------------------------------------------------
		if fcp:getPreference("FFPeriodicBackupInterval") == nil then
			mod.FFPeriodicBackupInterval = 15
		else
			mod.FFPeriodicBackupInterval = fcp:getPreference("FFPeriodicBackupInterval")
		end

		--------------------------------------------------------------------------------
		-- If Final Cut Pro is running...
		--------------------------------------------------------------------------------
		local restartStatus = false
		if fcp:isRunning() then
			if dialog.displayYesNoQuestion(i18n("changeBackupInterval") .. "\n\n" .. doYouWantToContinue) then
				restartStatus = true
			else
				return "Done"
			end
		end

		--------------------------------------------------------------------------------
		-- Ask user what to set the backup interval to:
		--------------------------------------------------------------------------------
		local userSelectedBackupInterval = dialog.displaySmallNumberTextBoxMessage(i18n("changeBackupIntervalTextbox"), i18n("changeBackupIntervalError"), mod.FFPeriodicBackupInterval)
		if not userSelectedBackupInterval then
			return "Cancel"
		end

		--------------------------------------------------------------------------------
		-- Update plist:
		--------------------------------------------------------------------------------
		local result = fcp:setPreference("FFPeriodicBackupInterval", tostring(userSelectedBackupInterval))
		if result == nil then
			dialog.displayErrorMessage(i18n("backupIntervalFail"))
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Refresh Menubar:
		--------------------------------------------------------------------------------
		refreshMenuBar(true)

		--------------------------------------------------------------------------------
		-- Restart Final Cut Pro:
		--------------------------------------------------------------------------------
		if restartStatus then
			if not fcp:restart() then
				--------------------------------------------------------------------------------
				-- Failed to restart Final Cut Pro:
				--------------------------------------------------------------------------------
				dialog.displayErrorMessage(i18n("failedToRestart"))
				return "Failed"
			end
		end

	end

	--------------------------------------------------------------------------------
	-- CHANGE SMART COLLECTIONS LABEL:
	--------------------------------------------------------------------------------
	function changeSmartCollectionsLabel()

		--------------------------------------------------------------------------------
		-- Delete any pre-existing highlights:
		--------------------------------------------------------------------------------
		deleteAllHighlights()

		--------------------------------------------------------------------------------
		-- Get existing value:
		--------------------------------------------------------------------------------
		local executeResult,executeStatus = execute("/usr/libexec/PlistBuddy -c \"Print :FFOrganizerSmartCollections\" '" .. fcp:getPath() .. "/Contents/Frameworks/Flexo.framework/Versions/A/Resources/en.lproj/FFLocalizable.strings'")
		if tools.trim(executeResult) ~= "" then FFOrganizerSmartCollections = executeResult end

		--------------------------------------------------------------------------------
		-- If Final Cut Pro is running...
		--------------------------------------------------------------------------------
		local restartStatus = false
		if fcp:isRunning() then
			if dialog.displayYesNoQuestion(i18n("changeSmartCollectionsLabel") .. "\n\n" .. i18n("doYouWantToContinue")) then
				restartStatus = true
			else
				return "Done"
			end
		end

		--------------------------------------------------------------------------------
		-- Ask user what to set the backup interval to:
		--------------------------------------------------------------------------------
		local userSelectedSmartCollectionsLabel = dialog.displayTextBoxMessage(i18n("smartCollectionsLabelTextbox"), i18n("smartCollectionsLabelError"), tools.trim(FFOrganizerSmartCollections))
		if not userSelectedSmartCollectionsLabel then
			return "Cancel"
		end

		--------------------------------------------------------------------------------
		-- Update plist for every Flexo language:
		--------------------------------------------------------------------------------
		local executeCommands = {}
		for k, v in pairs(fcp:getFlexoLanguages()) do
			local executeCommand = "/usr/libexec/PlistBuddy -c \"Set :FFOrganizerSmartCollections " .. tools.trim(userSelectedSmartCollectionsLabel) .. "\" '" .. fcp:getPath() .. "/Contents/Frameworks/Flexo.framework/Versions/A/Resources/" .. fcp:getFlexoLanguages()[k] .. ".lproj/FFLocalizable.strings'"
			executeCommands[#executeCommands + 1] = executeCommand
		end
		local result = tools.executeWithAdministratorPrivileges(executeCommands)
		if not result then
			dialog.displayErrorMessage("Failed to change Smart Collection Label.")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Restart Final Cut Pro:
		--------------------------------------------------------------------------------
		if restartStatus then
			if not fcp:restart() then
				--------------------------------------------------------------------------------
				-- Failed to restart Final Cut Pro:
				--------------------------------------------------------------------------------
				dialog.displayErrorMessage(i18n("failedToRestart"))
				return "Failed"
			end
		end

	end

--------------------------------------------------------------------------------
-- TOGGLE:
--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- TOGGLE VOICE COMMAND ENABLE ANNOUNCEMENTS:
	--------------------------------------------------------------------------------
	function toggleVoiceCommandEnableAnnouncements()
		local voiceCommandEnableAnnouncements = settings.get("fcpxHacks.voiceCommandEnableAnnouncements")
		settings.set("fcpxHacks.voiceCommandEnableAnnouncements", not voiceCommandEnableAnnouncements)
		refreshMenuBar()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE VOICE COMMAND ENABLE VISUAL ALERTS:
	--------------------------------------------------------------------------------
	function toggleVoiceCommandEnableVisualAlerts()
		local voiceCommandEnableVisualAlerts = settings.get("fcpxHacks.voiceCommandEnableVisualAlerts")
		settings.set("fcpxHacks.voiceCommandEnableVisualAlerts", not voiceCommandEnableVisualAlerts)
		refreshMenuBar()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE SCROLLING TIMELINE:
	--------------------------------------------------------------------------------
	function toggleScrollingTimeline()

		--------------------------------------------------------------------------------
		-- Toggle Scrolling Timeline:
		--------------------------------------------------------------------------------
		local scrollingTimelineActivated = settings.get("fcpxHacks.scrollingTimelineActive") or false
		if scrollingTimelineActivated then
			--------------------------------------------------------------------------------
			-- Update Settings:
			--------------------------------------------------------------------------------
			settings.set("fcpxHacks.scrollingTimelineActive", false)

			--------------------------------------------------------------------------------
			-- Stop Watchers:
			--------------------------------------------------------------------------------
			mod.scrollingTimelineWatcherDown:stop()
			fcp:timeline():unlockPlayhead()

			--------------------------------------------------------------------------------
			-- Display Notification:
			--------------------------------------------------------------------------------
			dialog.displayNotification(i18n("scrollingTimelineDeactivated"))

		else
			--------------------------------------------------------------------------------
			-- Ensure that Playhead Lock is Off:
			--------------------------------------------------------------------------------
			local message = ""
			local lockTimelinePlayhead = settings.get("fcpxHacks.lockTimelinePlayhead") or false
			if lockTimelinePlayhead then
				toggleLockPlayhead()
				message = i18n("playheadLockDeactivated") .. "\n"
			end

			--------------------------------------------------------------------------------
			-- Update Settings:
			--------------------------------------------------------------------------------
			settings.set("fcpxHacks.scrollingTimelineActive", true)

			--------------------------------------------------------------------------------
			-- Start Watchers:
			--------------------------------------------------------------------------------
			mod.scrollingTimelineWatcherDown:start()

			--------------------------------------------------------------------------------
			-- If activated whilst already playing, then turn on Scrolling Timeline:
			--------------------------------------------------------------------------------
			checkScrollingTimeline()

			--------------------------------------------------------------------------------
			-- Display Notification:
			--------------------------------------------------------------------------------
			dialog.displayNotification(message..i18n("scrollingTimelineActivated"))

		end

		--------------------------------------------------------------------------------
		-- Refresh Menu Bar:
		--------------------------------------------------------------------------------
		refreshMenuBar()

	end

	--------------------------------------------------------------------------------
	-- TOGGLE LOCK PLAYHEAD:
	--------------------------------------------------------------------------------
	function toggleLockPlayhead()

		local lockTimelinePlayhead = settings.get("fcpxHacks.lockTimelinePlayhead") or false

		if lockTimelinePlayhead then
			if fcp:isRunning() then
				fcp:timeline():unlockPlayhead()
			end
			dialog.displayNotification(i18n("playheadLockDeactivated"))
			settings.set("fcpxHacks.lockTimelinePlayhead", false)
		else
			local message = ""
			--------------------------------------------------------------------------------
			-- Ensure that Scrolling Timeline is off
			--------------------------------------------------------------------------------
			local scrollingTimeline = settings.get("fcpxHacks.scrollingTimelineActive") or false
			if scrollingTimeline then
				toggleScrollingTimeline()
				message = i18n("scrollingTimelineDeactivated") .. "\n"
			end
			if fcp:isRunning() then
				fcp:timeline():lockPlayhead()
			end
			dialog.displayNotification(message..i18n("playheadLockActivated"))
			settings.set("fcpxHacks.lockTimelinePlayhead", true)
		end

		refreshMenuBar()

	end

	--------------------------------------------------------------------------------
	-- TOGGLE BATCH EXPORT REPLACE EXISTING FILES:
	--------------------------------------------------------------------------------
	function toggleBatchExportReplaceExistingFiles()
		local batchExportReplaceExistingFiles = settings.get("fcpxHacks.batchExportReplaceExistingFiles")
		settings.set("fcpxHacks.batchExportReplaceExistingFiles", not batchExportReplaceExistingFiles)
		refreshMenuBar()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE ENABLE HACKS HUD:
	--------------------------------------------------------------------------------
	function toggleEnableVoiceCommands()

		local enableVoiceCommands = settings.get("fcpxHacks.enableVoiceCommands")
		settings.set("fcpxHacks.enableVoiceCommands", not enableVoiceCommands)

		if enableVoiceCommands then
			voicecommands:stop()
		else
			local result = voicecommands:new()
			if result == false then
				dialog.displayErrorMessage(i18n("voiceCommandsError"))
				settings.set("fcpxHacks.enableVoiceCommands", enableVoiceCommands)
				return
			end
			if fcp:isFrontmost() then
				voicecommands:start()
			else
				voicecommands:stop()
			end
		end
		refreshMenuBar()

	end

	--------------------------------------------------------------------------------
	-- TOGGLE ENABLE HACKS HUD:
	--------------------------------------------------------------------------------
	function toggleEnableHacksHUD()
		local enableHacksHUD = settings.get("fcpxHacks.enableHacksHUD")
		settings.set("fcpxHacks.enableHacksHUD", not enableHacksHUD)

		if enableHacksHUD then
			hackshud.hide()
		else
			if fcp:isFrontmost() then
				hackshud.show()
			end
		end

		refreshMenuBar()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE DEBUG MODE:
	--------------------------------------------------------------------------------
	function toggleDebugMode()
		mod.debugMode = not mod.debugMode

		if mod.debugMode then
			logger.defaultLogLevel = 'warn'
		else
			logger.defaultLogLevel = 'debug'
		end

		settings.set("fcpxHacks.debugMode", mod.debugMode)
		refreshMenuBar()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE CHECK FOR UPDATES:
	--------------------------------------------------------------------------------
	function toggleCheckForUpdates()
		local enableCheckForUpdates = settings.get("fcpxHacks.enableCheckForUpdates")
		settings.set("fcpxHacks.enableCheckForUpdates", not enableCheckForUpdates)
		refreshMenuBar()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE MENUBAR DISPLAY:
	--------------------------------------------------------------------------------
	function toggleMenubarDisplay(value)
		local menubarEnabled = settings.get("fcpxHacks.menubar" .. value .. "Enabled")
		settings.set("fcpxHacks.menubar" .. value .. "Enabled", not menubarEnabled)
		refreshMenuBar()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE HUD OPTION:
	--------------------------------------------------------------------------------
	function toggleHUDOption(value)
		local result = settings.get("fcpxHacks." .. value)
		settings.set("fcpxHacks." .. value, not result)
		hackshud.reload()
		refreshMenuBar()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE MEDIA IMPORT WATCHER:
	--------------------------------------------------------------------------------
	function toggleMediaImportWatcher()
		local enableMediaImportWatcher = settings.get("fcpxHacks.enableMediaImportWatcher") or false
		if not enableMediaImportWatcher then
			mediaImportWatcher()
		else
			mod.newDeviceMounted:stop()
		end
		settings.set("fcpxHacks.enableMediaImportWatcher", not enableMediaImportWatcher)
		refreshMenuBar()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE CLIPBOARD HISTORY:
	--------------------------------------------------------------------------------
	function toggleEnableClipboardHistory()
		local enableClipboardHistory = settings.get("fcpxHacks.enableClipboardHistory") or false
		if not enableClipboardHistory then
			clipboard.startWatching()
		else
			clipboard.stopWatching()
		end
		settings.set("fcpxHacks.enableClipboardHistory", not enableClipboardHistory)
		refreshMenuBar()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE SHARED CLIPBOARD:
	--------------------------------------------------------------------------------
	function toggleEnableSharedClipboard()

		local enableSharedClipboard = settings.get("fcpxHacks.enableSharedClipboard") or false

		if not enableSharedClipboard then

			result = dialog.displayChooseFolder("Which folder would you like to use for the Shared Clipboard?")

			if result ~= false then
				debugMessage("Enabled Shared Clipboard Path: " .. tostring(result))
				settings.set("fcpxHacks.sharedClipboardPath", result)

				--------------------------------------------------------------------------------
				-- Watch for Shared Clipboard Changes:
				--------------------------------------------------------------------------------
				sharedClipboardWatcher = pathwatcher.new(result, sharedClipboardFileWatcher):start()

			else
				debugMessage("Enabled Shared Clipboard Choose Path Cancelled.")
				settings.set("fcpxHacks.sharedClipboardPath", nil)
				return "failed"
			end

		else

			--------------------------------------------------------------------------------
			-- Stop Watching for Shared Clipboard Changes:
			--------------------------------------------------------------------------------
			sharedClipboardWatcher:stop()

		end

		settings.set("fcpxHacks.enableSharedClipboard", not enableSharedClipboard)
		refreshMenuBar()

	end

	--------------------------------------------------------------------------------
	-- TOGGLE XML SHARING:
	--------------------------------------------------------------------------------
	function toggleEnableXMLSharing()

		local enableXMLSharing = settings.get("fcpxHacks.enableXMLSharing") or false

		if not enableXMLSharing then

			xmlSharingPath = dialog.displayChooseFolder("Which folder would you like to use for XML Sharing?")

			if xmlSharingPath ~= false then
				settings.set("fcpxHacks.xmlSharingPath", xmlSharingPath)
			else
				settings.set("fcpxHacks.xmlSharingPath", nil)
				return "Cancelled"
			end

			--------------------------------------------------------------------------------
			-- Watch for Shared XML Folder Changes:
			--------------------------------------------------------------------------------
			sharedXMLWatcher = pathwatcher.new(xmlSharingPath, sharedXMLFileWatcher):start()

		else
			--------------------------------------------------------------------------------
			-- Stop Watchers:
			--------------------------------------------------------------------------------
			sharedXMLWatcher:stop()

			--------------------------------------------------------------------------------
			-- Clear Settings:
			--------------------------------------------------------------------------------
			settings.set("fcpxHacks.xmlSharingPath", nil)
		end

		settings.set("fcpxHacks.enableXMLSharing", not enableXMLSharing)
		refreshMenuBar()

	end

	--------------------------------------------------------------------------------
	-- TOGGLE MOBILE NOTIFICATIONS:
	--------------------------------------------------------------------------------
	function toggleEnableMobileNotifications()
		local enableMobileNotifications 	= settings.get("fcpxHacks.enableMobileNotifications") or false
		local prowlAPIKey 					= settings.get("fcpxHacks.prowlAPIKey") or ""

		if not enableMobileNotifications then

			local returnToFinalCutPro = fcp:isFrontmost()
			::retryProwlAPIKeyEntry::

			local result = dialog.displayTextBoxMessage(i18n("mobileNotificationsTextbox"), i18n("mobileNotificationsError") .. "\n\n" .. i18n("pleaseTryAgain"), prowlAPIKey)

			if result == false then
				return "Cancel"
			end
			local prowlAPIKeyValidResult, prowlAPIKeyValidError = prowlAPIKeyValid(result)
			if prowlAPIKeyValidResult then
				if returnToFinalCutPro then fcp:launch() end
				settings.set("fcpxHacks.prowlAPIKey", result)
				notificationWatcher()
				settings.set("fcpxHacks.enableMobileNotifications", not enableMobileNotifications)
			else
				dialog.displayMessage(i18n("prowlError") .. " " .. prowlAPIKeyValidError .. ".\n\n" .. i18n("pleaseTryAgain"))
				goto retryProwlAPIKeyEntry
			end
		else
			shareSuccessNotificationWatcher:stop()
			shareFailedNotificationWatcher:stop()
			settings.set("fcpxHacks.enableMobileNotifications", not enableMobileNotifications)
		end
		refreshMenuBar()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE HAMMERSPOON DOCK ICON:
	--------------------------------------------------------------------------------
	function toggleHammerspoonDockIcon()
		local originalValue = hs.dockIcon()
		hs.dockIcon(not originalValue)
		refreshMenuBar()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE HAMMERSPOON MENU ICON:
	--------------------------------------------------------------------------------
	function toggleHammerspoonMenuIcon()
		local originalValue = hs.menuIcon()
		hs.menuIcon(not originalValue)
		refreshMenuBar()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE LAUNCH HAMMERSPOON ON START:
	--------------------------------------------------------------------------------
	function toggleLaunchHammerspoonOnStartup()
		local originalValue = hs.autoLaunch()
		hs.autoLaunch(not originalValue)
		refreshMenuBar()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE HAMMERSPOON CHECK FOR UPDATES:
	--------------------------------------------------------------------------------
	function toggleCheckforHammerspoonUpdates()
		local originalValue = hs.automaticallyCheckForUpdates()
		hs.automaticallyCheckForUpdates(not originalValue)
		refreshMenuBar()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE ENABLE PROXY MENU ICON:
	--------------------------------------------------------------------------------
	function toggleEnableProxyMenuIcon()
		local enableProxyMenuIcon = settings.get("fcpxHacks.enableProxyMenuIcon")
		if enableProxyMenuIcon == nil then
			settings.set("fcpxHacks.enableProxyMenuIcon", true)
			enableProxyMenuIcon = true
		else
			settings.set("fcpxHacks.enableProxyMenuIcon", not enableProxyMenuIcon)
		end

		updateMenubarIcon()
		refreshMenuBar()

	end

	--------------------------------------------------------------------------------
	-- TOGGLE HACKS SHORTCUTS IN FINAL CUT PRO:
	--------------------------------------------------------------------------------
	function toggleEnableHacksShortcutsInFinalCutPro()

		--------------------------------------------------------------------------------
		-- Get current value from settings:
		--------------------------------------------------------------------------------
		local enableHacksShortcutsInFinalCutPro = settings.get("fcpxHacks.enableHacksShortcutsInFinalCutPro")
		if enableHacksShortcutsInFinalCutPro == nil then enableHacksShortcutsInFinalCutPro = false end

		--------------------------------------------------------------------------------
		-- Are we enabling or disabling?
		--------------------------------------------------------------------------------
		local enableOrDisableText = nil
		if enableHacksShortcutsInFinalCutPro then
			enableOrDisableText = "Disabling"
		else
			enableOrDisableText = "Enabling"
		end

		--------------------------------------------------------------------------------
		-- If Final Cut Pro is running...
		--------------------------------------------------------------------------------
		local restartStatus = false
		if fcp:isRunning() then
			if dialog.displayYesNoQuestion(enableOrDisableText .. " " .. i18n("hacksShortcutsRestart") .. " " .. i18n("doYouWantToContinue")) then
				restartStatus = true
			else
				return "Done"
			end
		else
			if not dialog.displayYesNoQuestion(enableOrDisableText .. " " .. i18n("hacksShortcutAdminPassword") .. " " .. i18n("doYouWantToContinue")) then
				return "Done"
			end
		end

		--------------------------------------------------------------------------------
		-- Let's do it!
		--------------------------------------------------------------------------------
		local saveSettings = false
		if enableHacksShortcutsInFinalCutPro then
			--------------------------------------------------------------------------------
			-- Revert back to default keyboard layout:
			--------------------------------------------------------------------------------
			local result = fcp:setPreference("Active Command Set", fcp:getPath() .. "/Contents/Resources/en.lproj/Default.commandset")
			if result == nil then
				dialog.displayErrorMessage(i18n("activeCommandSetResetError"))
				return "Failed"
			end

			--------------------------------------------------------------------------------
			-- Disable Hacks Shortcut in Final Cut Pro:
			--------------------------------------------------------------------------------
			local result = disableHacksShortcuts()
			if result ~= "Done" then
				dialog.displayErrorMessage(i18n("failedToReplaceFile") .. "\n\n" .. result)
				return false
			end
		else
			--------------------------------------------------------------------------------
			-- Revert back to default keyboard layout:
			--------------------------------------------------------------------------------
			local result = fcp:setPreference("Active Command Set", fcp:getPath() .. "/Contents/Resources/en.lproj/Default.commandset")
			if result == nil then
				dialog.displayErrorMessage(i18n("activeCommandSetResetError"))
				return "Failed"
			end

			--------------------------------------------------------------------------------
			-- Enable Hacks Shortcut in Final Cut Pro:
			--------------------------------------------------------------------------------
			local result = enableHacksShortcuts()
			if result ~= "Done" then
				dialog.displayErrorMessage(i18n("failedToReplaceFile") .. "\n\n" .. result)
				return false
			end
		end


		--------------------------------------------------------------------------------
		-- Save new value to settings:
		--------------------------------------------------------------------------------
		settings.set("fcpxHacks.enableHacksShortcutsInFinalCutPro", not enableHacksShortcutsInFinalCutPro)

		--------------------------------------------------------------------------------
		-- Restart Final Cut Pro:
		--------------------------------------------------------------------------------
		if restartStatus then
			if not fcp:restart() then
				--------------------------------------------------------------------------------
				-- Failed to restart Final Cut Pro:
				--------------------------------------------------------------------------------
				dialog.displayErrorMessage(i18n("failedToRestart"))
				return "Failed"
			end
		end

		--------------------------------------------------------------------------------
		-- Refresh the Keyboard Shortcuts:
		--------------------------------------------------------------------------------
		bindKeyboardShortcuts()

		--------------------------------------------------------------------------------
		-- Refresh the Menu Bar:
		--------------------------------------------------------------------------------
		refreshMenuBar()

	end

	--------------------------------------------------------------------------------
	-- TOGGLE ENABLE SHORTCUTS DURING FULLSCREEN PLAYBACK:
	--------------------------------------------------------------------------------
	function toggleEnableShortcutsDuringFullscreenPlayback()

		local enableShortcutsDuringFullscreenPlayback = settings.get("fcpxHacks.enableShortcutsDuringFullscreenPlayback")
		if enableShortcutsDuringFullscreenPlayback == nil then enableShortcutsDuringFullscreenPlayback = false end
		settings.set("fcpxHacks.enableShortcutsDuringFullscreenPlayback", not enableShortcutsDuringFullscreenPlayback)

		if enableShortcutsDuringFullscreenPlayback == true then
			fullscreenKeyboardWatcherUp:stop()
			fullscreenKeyboardWatcherDown:stop()
		else
			fullscreenKeyboardWatcherUp:start()
			fullscreenKeyboardWatcherDown:start()
		end

		refreshMenuBar()

	end

	--------------------------------------------------------------------------------
	-- TOGGLE MOVING MARKERS:
	--------------------------------------------------------------------------------
	function toggleMovingMarkers()

		--------------------------------------------------------------------------------
		-- Delete any pre-existing highlights:
		--------------------------------------------------------------------------------
		deleteAllHighlights()

		--------------------------------------------------------------------------------
		-- Get existing value:
		--------------------------------------------------------------------------------
		mod.allowMovingMarkers = false
		local executeResult,executeStatus = execute("/usr/libexec/PlistBuddy -c \"Print :TLKMarkerHandler:Configuration:'Allow Moving Markers'\" '" .. fcp:getPath() .. "/Contents/Frameworks/TLKit.framework/Versions/A/Resources/EventDescriptions.plist'")
		if tools.trim(executeResult) == "true" then mod.allowMovingMarkers = true end

		--------------------------------------------------------------------------------
		-- If Final Cut Pro is running...
		--------------------------------------------------------------------------------
		local restartStatus = false
		if fcp:isRunning() then
			if dialog.displayYesNoQuestion(i18n("togglingMovingMarkersRestart") .. "\n\n" .. i18n("doYouWantToContinue")) then
				restartStatus = true
			else
				return "Done"
			end
		end

		--------------------------------------------------------------------------------
		-- Update plist:
		--------------------------------------------------------------------------------
		if mod.allowMovingMarkers then
			local executeStatus = tools.executeWithAdministratorPrivileges([[/usr/libexec/PlistBuddy -c \"Set :TLKMarkerHandler:Configuration:'Allow Moving Markers' false\" ']] .. fcp:getPath() .. [[/Contents/Frameworks/TLKit.framework/Versions/A/Resources/EventDescriptions.plist']])
			if executeStatus == false then
				dialog.displayErrorMessage(i18n("movingMarkersError"))
				return "Failed"
			end
		else
			local executeStatus = tools.executeWithAdministratorPrivileges([[/usr/libexec/PlistBuddy -c \"Set :TLKMarkerHandler:Configuration:'Allow Moving Markers' true\" ']] .. fcp:getPath() .. [[/Contents/Frameworks/TLKit.framework/Versions/A/Resources/EventDescriptions.plist']])
			if executeStatus == false then
				dialog.displayErrorMessage(i18n("movingMarkersError"))
				return "Failed"
			end
		end

		--------------------------------------------------------------------------------
		-- Restart Final Cut Pro:
		--------------------------------------------------------------------------------
		if restartStatus then
			if not fcp:restart() then
				--------------------------------------------------------------------------------
				-- Failed to restart Final Cut Pro:
				--------------------------------------------------------------------------------
				dialog.displayErrorMessage(i18n("failedToRestart"))
				return "Failed"
			end
		end

		--------------------------------------------------------------------------------
		-- Refresh Menu Bar:
		--------------------------------------------------------------------------------
		refreshMenuBar(true)

	end

	--------------------------------------------------------------------------------
	-- TOGGLE PERFORM TASKS DURING PLAYBACK:
	--------------------------------------------------------------------------------
	function togglePerformTasksDuringPlayback()

		--------------------------------------------------------------------------------
		-- Delete any pre-existing highlights:
		--------------------------------------------------------------------------------
		deleteAllHighlights()

		--------------------------------------------------------------------------------
		-- Get existing value:
		--------------------------------------------------------------------------------
		if fcp:getPreference("FFSuspendBGOpsDuringPlay") == nil then
			mod.FFSuspendBGOpsDuringPlay = false
		else
			mod.FFSuspendBGOpsDuringPlay = fcp:getPreference("FFSuspendBGOpsDuringPlay")
		end

		--------------------------------------------------------------------------------
		-- If Final Cut Pro is running...
		--------------------------------------------------------------------------------
		local restartStatus = false
		if fcp:isRunning() then
			if dialog.displayYesNoQuestion(i18n("togglingBackgroundTasksRestart") .. "\n\n" ..i18n("doYouWantToContinue")) then
				restartStatus = true
			else
				return "Done"
			end
		end

		--------------------------------------------------------------------------------
		-- Update plist:
		--------------------------------------------------------------------------------
		local result = fcp:setPreference("FFSuspendBGOpsDuringPlay", not mod.FFSuspendBGOpsDuringPlay)
		if result == nil then
			dialog.displayErrorMessage(i18n("failedToWriteToPreferences"))
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Restart Final Cut Pro:
		--------------------------------------------------------------------------------
		if restartStatus then
			if not fcp:restart() then
				--------------------------------------------------------------------------------
				-- Failed to restart Final Cut Pro:
				--------------------------------------------------------------------------------
				dialog.displayErrorMessage(i18n("failedToRestart"))
				return "Failed"
			end
		end

		--------------------------------------------------------------------------------
		-- Refresh Menu Bar:
		--------------------------------------------------------------------------------
		refreshMenuBar(true)

	end

	--------------------------------------------------------------------------------
	-- TOGGLE TIMECODE OVERLAY:
	--------------------------------------------------------------------------------
	function toggleTimecodeOverlay()

		--------------------------------------------------------------------------------
		-- Delete any pre-existing highlights:
		--------------------------------------------------------------------------------
		deleteAllHighlights()

		--------------------------------------------------------------------------------
		-- Get existing value:
		--------------------------------------------------------------------------------
		if fcp:getPreference("FFEnableGuards") == nil then
			mod.FFEnableGuards = false
		else
			mod.FFEnableGuards = fcp:getPreference("FFEnableGuards")
		end

		--------------------------------------------------------------------------------
		-- If Final Cut Pro is running...
		--------------------------------------------------------------------------------
		local restartStatus = false
		if fcp:isRunning() then
			if dialog.displayYesNoQuestion(i18n("togglingTimecodeOverlayRestart") .. "\n\n" .. i18n("doYouWantToContinue")) then
				restartStatus = true
			else
				return "Done"
			end
		end

		--------------------------------------------------------------------------------
		-- Update plist:
		--------------------------------------------------------------------------------
		local result = fcp:setPreference("FFEnableGuards", not mod.FFEnableGuards)
		if result == nil then
			dialog.displayErrorMessage(i18n("failedToWriteToPreferences"))
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Restart Final Cut Pro:
		--------------------------------------------------------------------------------
		if restartStatus then
			if not fcp:restart() then
				--------------------------------------------------------------------------------
				-- Failed to restart Final Cut Pro:
				--------------------------------------------------------------------------------
				dialog.displayErrorMessage(i18n("failedToRestart"))
				return "Failed"
			end
		end

		--------------------------------------------------------------------------------
		-- Refresh Menu Bar:
		--------------------------------------------------------------------------------
		refreshMenuBar(true)

	end

	--------------------------------------------------------------------------------
	-- TOGGLE MENUBAR DISPLAY MODE:
	--------------------------------------------------------------------------------
	function toggleMenubarDisplayMode()

		local displayMenubarAsIcon = settings.get("fcpxHacks.displayMenubarAsIcon")


		if displayMenubarAsIcon == nil then
			 settings.set("fcpxHacks.displayMenubarAsIcon", true)
		else
			if displayMenubarAsIcon then
				settings.set("fcpxHacks.displayMenubarAsIcon", false)
			else
				settings.set("fcpxHacks.displayMenubarAsIcon", true)
			end
		end

		updateMenubarIcon()
		refreshMenuBar()

	end

	--------------------------------------------------------------------------------
	-- TOGGLE CREATE MULTI-CAM OPTIMISED MEDIA:
	--------------------------------------------------------------------------------
	function toggleCreateMulticamOptimizedMedia(optionalValue)

		--------------------------------------------------------------------------------
		-- Make sure it's active:
		--------------------------------------------------------------------------------
		fcp:launch()

		--------------------------------------------------------------------------------
		-- If we're setting rather than toggling...
		--------------------------------------------------------------------------------
		log.d("optionalValue: "..inspect(optionalValue))
		if optionalValue ~= nil and optionalValue == fcp:getPreference("FFCreateOptimizedMediaForMulticamClips", true) then
			log.d("optionalValue matches preference value. Bailing.")
			return
		end

		--------------------------------------------------------------------------------
		-- Define FCPX:
		--------------------------------------------------------------------------------
		local prefs = fcp:preferencesWindow()

		--------------------------------------------------------------------------------
		-- Toggle the checkbox:
		--------------------------------------------------------------------------------
		if not prefs:playbackPanel():toggleCreateOptimizedMediaForMulticamClips() then
			dialog.displayErrorMessage("Failed to toggle 'Create Optimized Media for Multicam Clips'.\n\nError occurred in toggleCreateMulticamOptimizedMedia().")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Close the Preferences window:
		--------------------------------------------------------------------------------
		prefs:hide()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE CREATE PROXY MEDIA:
	--------------------------------------------------------------------------------
	function toggleCreateProxyMedia(optionalValue)

		--------------------------------------------------------------------------------
		-- Make sure it's active:
		--------------------------------------------------------------------------------
		fcp:launch()

		--------------------------------------------------------------------------------
		-- If we're setting rather than toggling...
		--------------------------------------------------------------------------------
		if optionalValue ~= nil and optionalValue == fcp:getPreference("FFImportCreateProxyMedia", false) then
			return
		end

		--------------------------------------------------------------------------------
		-- Define FCPX:
		--------------------------------------------------------------------------------
		local prefs = fcp:preferencesWindow()

		--------------------------------------------------------------------------------
		-- Toggle the checkbox:
		--------------------------------------------------------------------------------
		if not prefs:importPanel():toggleCreateProxyMedia() then
			dialog.displayErrorMessage("Failed to toggle 'Create Proxy Media'.\n\nError occurred in toggleCreateProxyMedia().")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Close the Preferences window:
		--------------------------------------------------------------------------------
		prefs:hide()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE CREATE OPTIMIZED MEDIA:
	--------------------------------------------------------------------------------
	function toggleCreateOptimizedMedia(optionalValue)

		--------------------------------------------------------------------------------
		-- Make sure it's active:
		--------------------------------------------------------------------------------
		fcp:launch()

		--------------------------------------------------------------------------------
		-- If we're setting rather than toggling...
		--------------------------------------------------------------------------------
		if optionalValue ~= nil and optionalValue == fcp:getPreference("FFImportCreateOptimizeMedia", false) then
			return
		end

		--------------------------------------------------------------------------------
		-- Define FCPX:
		--------------------------------------------------------------------------------
		local prefs = fcp:preferencesWindow()

		--------------------------------------------------------------------------------
		-- Toggle the checkbox:
		--------------------------------------------------------------------------------
		if not prefs:importPanel():toggleCreateOptimizedMedia() then
			dialog.displayErrorMessage("Failed to toggle 'Create Optimized Media'.\n\nError occurred in toggleCreateOptimizedMedia().")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Close the Preferences window:
		--------------------------------------------------------------------------------
		prefs:hide()

	end

	--------------------------------------------------------------------------------
	-- TOGGLE LEAVE IN PLACE ON IMPORT:
	--------------------------------------------------------------------------------
	function toggleLeaveInPlace(optionalValue)

		--------------------------------------------------------------------------------
		-- Make sure it's active:
		--------------------------------------------------------------------------------
		fcp:launch()

		--------------------------------------------------------------------------------
		-- If we're setting rather than toggling...
		--------------------------------------------------------------------------------
		if optionalValue ~= nil and optionalValue == fcp:getPreference("FFImportCopyToMediaFolder", true) then
			return
		end

		--------------------------------------------------------------------------------
		-- Define FCPX:
		--------------------------------------------------------------------------------
		local prefs = fcp:preferencesWindow()

		--------------------------------------------------------------------------------
		-- Toggle the checkbox:
		--------------------------------------------------------------------------------
		if not prefs:importPanel():toggleCopyToMediaFolder() then
			dialog.displayErrorMessage("Failed to toggle 'Copy To Media Folder'.\n\nError occurred in toggleLeaveInPlace().")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Close the Preferences window:
		--------------------------------------------------------------------------------
		prefs:hide()

	end

	--------------------------------------------------------------------------------
	-- TOGGLE BACKGROUND RENDER:
	--------------------------------------------------------------------------------
	function toggleBackgroundRender(optionalValue)

		--------------------------------------------------------------------------------
		-- Make sure it's active:
		--------------------------------------------------------------------------------
		fcp:launch()

		--------------------------------------------------------------------------------
		-- If we're setting rather than toggling...
		--------------------------------------------------------------------------------
		if optionalValue ~= nil and optionalValue == fcp:getPreference("FFAutoStartBGRender", true) then
			return
		end

		--------------------------------------------------------------------------------
		-- Define FCPX:
		--------------------------------------------------------------------------------
		local prefs = fcp:preferencesWindow()

		--------------------------------------------------------------------------------
		-- Toggle the checkbox:
		--------------------------------------------------------------------------------
		if not prefs:playbackPanel():toggleAutoStartBGRender() then
			dialog.displayErrorMessage("Failed to toggle 'Enable Background Render'.\n\nError occurred in toggleBackgroundRender().")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Close the Preferences window:
		--------------------------------------------------------------------------------
		prefs:hide()

	end

--------------------------------------------------------------------------------
-- PASTE:
--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- PASTE FROM CLIPBOARD HISTORY:
	--------------------------------------------------------------------------------
	function finalCutProPasteFromClipboardHistory(data)

		--------------------------------------------------------------------------------
		-- Write data back to Clipboard:
		--------------------------------------------------------------------------------
		clipboard.stopWatching()
		pasteboard.writeDataForUTI(fcp:getPasteboardUTI(), data)
		clipboard.startWatching()

		--------------------------------------------------------------------------------
		-- Paste in FCPX:
		--------------------------------------------------------------------------------
		fcp:launch()
		if not fcp:performShortcut("Paste") then
			dialog.displayErrorMessage("Failed to trigger the 'Paste' Shortcut.\n\nError occurred in finalCutProPasteFromClipboardHistory().")
			return "Failed"
		end

	end

	--------------------------------------------------------------------------------
	-- PASTE FROM SHARED CLIPBOARD:
	--------------------------------------------------------------------------------
	function pasteFromSharedClipboard(pathToClipboardFile, whichClipboard)

		if tools.doesFileExist(pathToClipboardFile) then
			local plistData = plist.xmlFileToTable(pathToClipboardFile)
			if plistData ~= nil then

				--------------------------------------------------------------------------------
				-- Decode Shared Clipboard Data from Plist:
				--------------------------------------------------------------------------------
				local currentClipboardData = base64.decode(plistData["SharedClipboardData" .. whichClipboard])

				--------------------------------------------------------------------------------
				-- Write data back to Clipboard:
				--------------------------------------------------------------------------------
				clipboard.stopWatching()
				pasteboard.writeDataForUTI(fcp:getPasteboardUTI(), currentClipboardData)
				clipboard.startWatching()

				--------------------------------------------------------------------------------
				-- Paste in FCPX:
				--------------------------------------------------------------------------------
				fcp:launch()
				if not fcp:performShortcut("Paste") then
					dialog.displayErrorMessage("Failed to trigger the 'Paste' Shortcut.\n\nError occurred in pasteFromSharedClipboard().")
					return "Failed"
				end

			else
				dialog.errorMessage(i18n("sharedClipboardNotRead"))
				return "Fail"
			end
		else
			dialog.displayMessage(i18n("sharedClipboardFileNotFound"))
			return "Fail"
		end

	end

--------------------------------------------------------------------------------
-- CLEAR:
--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- CLEAR CLIPBOARD HISTORY:
	--------------------------------------------------------------------------------
	function clearClipboardHistory()
		clipboard.clearHistory()
		refreshMenuBar()
	end

	--------------------------------------------------------------------------------
	-- CLEAR SHARED CLIPBOARD HISTORY:
	--------------------------------------------------------------------------------
	function clearSharedClipboardHistory()
		local sharedClipboardPath = settings.get("fcpxHacks.sharedClipboardPath")
		for file in fs.dir(sharedClipboardPath) do
			 if file:sub(-10) == ".fcpxhacks" then
				os.remove(sharedClipboardPath .. file)
			 end
			 refreshMenuBar()
		end
	end

	--------------------------------------------------------------------------------
	-- CLEAR SHARED XML FILES:
	--------------------------------------------------------------------------------
	function clearSharedXMLFiles()

		local xmlSharingPath = settings.get("fcpxHacks.xmlSharingPath")
		for folder in fs.dir(xmlSharingPath) do
			if tools.doesDirectoryExist(xmlSharingPath .. "/" .. folder) then
				for file in fs.dir(xmlSharingPath .. "/" .. folder) do
					if file:sub(-7) == ".fcpxml" then
						os.remove(xmlSharingPath .. folder .. "/" .. file)
					end
				end
			end
		end
		refreshMenuBar()

	end

--------------------------------------------------------------------------------
-- OTHER:
--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- QUIT FCPX HACKS:
	--------------------------------------------------------------------------------
	function quitFCPXHacks()
		application("Hammerspoon"):kill()
	end

	--------------------------------------------------------------------------------
	-- OPEN HAMMERSPOON CONSOLE:
	--------------------------------------------------------------------------------
	function openHammerspoonConsole()
		hs.openConsole()
	end

	--------------------------------------------------------------------------------
	-- RESET SETTINGS:
	--------------------------------------------------------------------------------
	function resetSettings()

		local finalCutProRunning = fcp:isRunning()

		local resetMessage = i18n("trashFCPXHacksPreferences")
		if finalCutProRunning then
			resetMessage = resetMessage .. "\n\n" .. i18n("adminPasswordRequiredAndRestart")
		else
			resetMessage = resetMessage .. "\n\n" .. i18n("adminPasswordRequired")
		end

		if not dialog.displayYesNoQuestion(resetMessage) then
		 	return
		end

		--------------------------------------------------------------------------------
		-- Remove Hacks Shortcut in Final Cut Pro:
		--------------------------------------------------------------------------------
		local result = disableHacksShortcuts()
		if result ~= "Done" then
			dialog.displayErrorMessage(i18n("failedToReplaceFile") .. "\n\n" .. result)
			return
		end

		--------------------------------------------------------------------------------
		-- Trash all FCPX Hacks Settings:
		--------------------------------------------------------------------------------
		for i, v in ipairs(settings.getKeys()) do
			if (v:sub(1,10)) == "fcpxHacks." then
				settings.set(v, nil)
			end
		end

		--------------------------------------------------------------------------------
		-- Restart Final Cut Pro if running:
		--------------------------------------------------------------------------------
		if finalCutProRunning then
			if not fcp:restart() then
				--------------------------------------------------------------------------------
				-- Failed to restart Final Cut Pro:
				--------------------------------------------------------------------------------
				dialog.displayMessage(i18n("restartFinalCutProFailed"))
			end
		end

		--------------------------------------------------------------------------------
		-- Reload Hammerspoon:
		--------------------------------------------------------------------------------
		hs.reload()

	end

	--------------------------------------------------------------------------------
	-- GET SCRIPT UPDATE:
	--------------------------------------------------------------------------------
	function getScriptUpdate()
		os.execute('open "' .. fcpxhacks.updateURL .. '"')
	end

	--------------------------------------------------------------------------------
	-- GO TO LATENITE FILMS SITE:
	--------------------------------------------------------------------------------
	function gotoLateNiteSite()
		os.execute('open "' .. fcpxhacks.developerURL .. '"')
	end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------





--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   S H O R T C U T   F E A T U R E S                        --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- KEYWORDS:
--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- SAVE KEYWORDS:
	--------------------------------------------------------------------------------
	function saveKeywordSearches(whichButton)

		--------------------------------------------------------------------------------
		-- Delete any pre-existing highlights:
		--------------------------------------------------------------------------------
		deleteAllHighlights()

		--------------------------------------------------------------------------------
		-- Check to see if the Keyword Editor is already open:
		--------------------------------------------------------------------------------
		local fcpx = fcp:application()
		local fcpxElements = ax.applicationElement(fcpx)
		local whichWindow = nil
		for i=1, fcpxElements:attributeValueCount("AXChildren") do
			if fcpxElements[i]:attributeValue("AXRole") == "AXWindow" then
				if fcpxElements[i]:attributeValue("AXIdentifier") == "_NS:264" then
					whichWindow = i
				end
			end
		end
		if whichWindow == nil then
			dialog.displayMessage(i18n("keywordEditorAlreadyOpen"))
			return
		end
		fcpxElements = fcpxElements[whichWindow]

		--------------------------------------------------------------------------------
		-- Get Starting Textfield:
		--------------------------------------------------------------------------------
		local startTextField = nil
		for i=1, fcpxElements:attributeValueCount("AXChildren") do
			if startTextField == nil then
				if fcpxElements[i]:attributeValue("AXIdentifier") == "_NS:102" then
					startTextField = i
					goto startTextFieldDone
				end
			end
		end
		::startTextFieldDone::
		if startTextField == nil then
			--------------------------------------------------------------------------------
			-- Keyword Shortcuts Buttons isn't down:
			--------------------------------------------------------------------------------
			fcpxElements = ax.applicationElement(fcpx)[1] -- Refresh
			for i=1, fcpxElements:attributeValueCount("AXChildren") do
				if fcpxElements[i]:attributeValue("AXIdentifier") == "_NS:276" then
					keywordDisclosureTriangle = i
					goto keywordDisclosureTriangleDone
				end
			end
			::keywordDisclosureTriangleDone::
			if fcpxElements[keywordDisclosureTriangle] == nil then
				dialog.displayMessage(i18n("keywordShortcutsVisibleError"))
				return "Failed"
			else
				local keywordDisclosureTriangleResult = fcpxElements[keywordDisclosureTriangle]:performAction("AXPress")
				if keywordDisclosureTriangleResult == nil then
					dialog.displayMessage(i18n("keywordShortcutsVisibleError"))
					return "Failed"
				end
			end
		end

		--------------------------------------------------------------------------------
		-- Get Values from the Keyword Editor:
		--------------------------------------------------------------------------------
		local savedKeywordValues = {}
		local favoriteCount = 1
		local skipFirst = true
		for i=1, fcpxElements:attributeValueCount("AXChildren") do
			if fcpxElements[i]:attributeValue("AXRole") == "AXTextField" then
				if skipFirst then
					skipFirst = false
				else
					savedKeywordValues[favoriteCount] = fcpxElements[i]:attributeValue("AXHelp")
					favoriteCount = favoriteCount + 1
				end
			end
		end

		--------------------------------------------------------------------------------
		-- Save Values to Settings:
		--------------------------------------------------------------------------------
		local savedKeywords = settings.get("fcpxHacks.savedKeywords")
		if savedKeywords == nil then savedKeywords = {} end
		for i=1, 9 do
			if savedKeywords['Preset ' .. tostring(whichButton)] == nil then
				savedKeywords['Preset ' .. tostring(whichButton)] = {}
			end
			savedKeywords['Preset ' .. tostring(whichButton)]['Item ' .. tostring(i)] = savedKeywordValues[i]
		end
		settings.set("fcpxHacks.savedKeywords", savedKeywords)

		--------------------------------------------------------------------------------
		-- Saved:
		--------------------------------------------------------------------------------
		dialog.displayNotification(i18n("keywordPresetsSaved") .. " " .. tostring(whichButton))

	end

	--------------------------------------------------------------------------------
	-- RESTORE KEYWORDS:
	--------------------------------------------------------------------------------
	function restoreKeywordSearches(whichButton)

		--------------------------------------------------------------------------------
		-- Delete any pre-existing highlights:
		--------------------------------------------------------------------------------
		deleteAllHighlights()

		--------------------------------------------------------------------------------
		-- Get Values from Settings:
		--------------------------------------------------------------------------------
		local savedKeywords = settings.get("fcpxHacks.savedKeywords")
		local restoredKeywordValues = {}

		if savedKeywords == nil then
			dialog.displayMessage(i18n("noKeywordPresetsError"))
			return "Fail"
		end
		if savedKeywords['Preset ' .. tostring(whichButton)] == nil then
			dialog.displayMessage(i18n("noKeywordPresetError"))
			return "Fail"
		end
		for i=1, 9 do
			restoredKeywordValues[i] = savedKeywords['Preset ' .. tostring(whichButton)]['Item ' .. tostring(i)]
		end

		--------------------------------------------------------------------------------
		-- Check to see if the Keyword Editor is already open:
		--------------------------------------------------------------------------------
		local fcpx = fcp:application()
		local fcpxElements = ax.applicationElement(fcpx)
		local whichWindow = nil
		for i=1, fcpxElements:attributeValueCount("AXChildren") do
			if fcpxElements[i]:attributeValue("AXRole") == "AXWindow" then
				if fcpxElements[i]:attributeValue("AXIdentifier") == "_NS:264" then
					whichWindow = i
				end
			end
		end
		if whichWindow == nil then
			dialog.displayMessage(i18n("keywordEditorAlreadyOpen"))
			return
		end
		fcpxElements = fcpxElements[whichWindow]

		--------------------------------------------------------------------------------
		-- Get Starting Textfield:
		--------------------------------------------------------------------------------
		local startTextField = nil
		for i=1, fcpxElements:attributeValueCount("AXChildren") do
			if startTextField == nil then
				if fcpxElements[i]:attributeValue("AXIdentifier") == "_NS:102" then
					startTextField = i
					goto startTextFieldDone
				end
			end
		end
		::startTextFieldDone::
		if startTextField == nil then
			--------------------------------------------------------------------------------
			-- Keyword Shortcuts Buttons isn't down:
			--------------------------------------------------------------------------------
			local keywordDisclosureTriangle = nil
			for i=1, fcpxElements:attributeValueCount("AXChildren") do
				if fcpxElements[i]:attributeValue("AXIdentifier") == "_NS:276" then
					keywordDisclosureTriangle = i
					goto keywordDisclosureTriangleDone
				end
			end
			::keywordDisclosureTriangleDone::

			if fcpxElements[keywordDisclosureTriangle] ~= nil then
				local keywordDisclosureTriangleResult = fcpxElements[keywordDisclosureTriangle]:performAction("AXPress")
				if keywordDisclosureTriangleResult == nil then
					dialog.displayMessage(i18n("keywordShortcutsVisibleError"))
					return "Failed"
				end
			else
				dialog.displayErrorMessage("Could not find keyword disclosure triangle.\n\nError occurred in restoreKeywordSearches().")
				return "Failed"
			end
		end

		--------------------------------------------------------------------------------
		-- Restore Values to Keyword Editor:
		--------------------------------------------------------------------------------
		local favoriteCount = 1
		local skipFirst = true
		for i=1, fcpxElements:attributeValueCount("AXChildren") do
			if fcpxElements[i]:attributeValue("AXRole") == "AXTextField" then
				if skipFirst then
					skipFirst = false
				else
					currentKeywordSelection = fcpxElements[i]

					setKeywordResult = currentKeywordSelection:setAttributeValue("AXValue", restoredKeywordValues[favoriteCount])
					keywordActionResult = currentKeywordSelection:setAttributeValue("AXFocused", true)
					eventtap.keyStroke({""}, "return")

					--------------------------------------------------------------------------------
					-- If at first you don't succeed, try, oh try, again!
					--------------------------------------------------------------------------------
					if fcpxElements[i][1]:attributeValue("AXValue") ~= restoredKeywordValues[favoriteCount] then
						setKeywordResult = currentKeywordSelection:setAttributeValue("AXValue", restoredKeywordValues[favoriteCount])
						keywordActionResult = currentKeywordSelection:setAttributeValue("AXFocused", true)
						eventtap.keyStroke({""}, "return")
					end

					favoriteCount = favoriteCount + 1
				end
			end
		end

		--------------------------------------------------------------------------------
		-- Successfully Restored:
		--------------------------------------------------------------------------------
		dialog.displayNotification(i18n("keywordPresetsRestored") .. " " .. tostring(whichButton))

	end

--------------------------------------------------------------------------------
-- MATCH FRAME RELATED:
--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- PERFORM MULTICAM MATCH FRAME:
	--------------------------------------------------------------------------------
	function multicamMatchFrame(goBackToTimeline) -- True or False

		local errorFunction = "\n\nError occurred in multicamMatchFrame()."

		--------------------------------------------------------------------------------
		-- Just in case:
		--------------------------------------------------------------------------------
		if goBackToTimeline == nil then goBackToTimeline = true end
		if type(goBackToTimeline) ~= "boolean" then goBackToTimeline = true end

		--------------------------------------------------------------------------------
		-- Delete any pre-existing highlights:
		--------------------------------------------------------------------------------
		deleteAllHighlights()

		--------------------------------------------------------------------------------
		-- Get Multicam Angle:
		--------------------------------------------------------------------------------
		local multicamAngle = getMulticamAngleFromSelectedClip()
		if multicamAngle == false then
			dialog.displayErrorMessage("Unfortunately we were not able to determine the currently selected Angle.\n\nPlease make sure you actually have a multicam clip selected.")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Open in Angle Editor:
		--------------------------------------------------------------------------------
		local menuBar = fcp:menuBar()
		if menuBar:isEnabled("Clip", "Open Clip") then
			menuBar:selectMenu("Clip", "Open Clip")
		else
			dialog.displayErrorMessage("Failed to open clip in Angle Editor.\n\nAre you sure the clip you have selected is a Multicam?" .. errorFunction)
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Put focus back on the timeline:
		--------------------------------------------------------------------------------
		if menuBar:isEnabled("Window", "Go To", "Timeline") then
			menuBar:selectMenu("Window", "Go To", "Timeline")
		else
			dialog.displayErrorMessage("Unable to return to timeline.\n\n" .. errorFunction)
			return
		end

		fcp:timeline():contents():selectClipInAngle(multicamAngle)

		--------------------------------------------------------------------------------
		-- Reveal In Browser:
		--------------------------------------------------------------------------------
		if menuBar:isEnabled("File", "Reveal in Browser") then
			menuBar:selectMenu("File", "Reveal in Browser")
		else
			dialog.displayErrorMessage("Unable to Reveal in Browser." .. errorFunction)
			return
		end

		--------------------------------------------------------------------------------
		-- Go back to original timeline if appropriate:
		--------------------------------------------------------------------------------
		if goBackToTimeline then
			if menuBar:isEnabled("View", "Timeline History Back") then
				menuBar:selectMenu("View", "Timeline History Back")
			else
				dialog.displayErrorMessage("Unable to go back to previous timeline." .. errorFunction)
				return
			end
		end

		--------------------------------------------------------------------------------
		-- Highlight Browser Playhead:
		--------------------------------------------------------------------------------
		highlightFCPXBrowserPlayhead()

	end

		--------------------------------------------------------------------------------
		-- GET MULTICAM ANGLE FROM SELECTED CLIP:
		--------------------------------------------------------------------------------
		function getMulticamAngleFromSelectedClip()

			local errorFunction =  " Error occurred in getMulticamAngleFromSelectedClip()."

			--------------------------------------------------------------------------------
			-- Ninja Pasteboard Copy:
			--------------------------------------------------------------------------------
			local result, clipboardData = ninjaPasteboardCopy()
			if not result then
				debugMessage("ERROR: Ninja Pasteboard Copy Failed." .. errorFunction)
				return false
			end

			--------------------------------------------------------------------------------
			-- Convert Binary Data to Table:
			--------------------------------------------------------------------------------
			local clipboardTable = plist.binaryToTable(clipboardData)
			if clipboardTable == nil then
				debugMessage("ERROR: Converting Binary Data to Table failed." .. errorFunction)
				return false
			end

			--------------------------------------------------------------------------------
			-- Read ffpasteboardobject from Table:
			--------------------------------------------------------------------------------
			local fcpxData = clipboardTable["ffpasteboardobject"]
			if fcpxData == nil then
				debugMessage("ERROR: Reading 'ffpasteboardobject' from Table failed." .. errorFunction)
				return false
			end

			--------------------------------------------------------------------------------
			-- Convert base64 Data to Table:
			--------------------------------------------------------------------------------
			local fcpxTable = plist.base64ToTable(fcpxData)
			if fcpxTable == nil then
				debugMessage("ERROR: Converting Binary Data to Table failed." .. errorFunction)
				return false
			end

			--------------------------------------------------------------------------------
			-- Check the item isMultiAngle:
			--------------------------------------------------------------------------------
			local isMultiAngle = false
			for k, v in pairs(fcpxTable["$objects"]) do
				if type(fcpxTable["$objects"][k]) == "table" then
					if fcpxTable["$objects"][k]["isMultiAngle"] then
						isMultiAngle = true
					end
				end
			end
			if not isMultiAngle then
				debugMessage("ERROR: The selected item is not a multi-angle clip." .. errorFunction)
				return false
			end

			--------------------------------------------------------------------------------
			-- Get FFAnchoredCollection ID:
			--------------------------------------------------------------------------------
			local FFAnchoredCollectionID = nil
			for k, v in pairs(fcpxTable["$objects"]) do
				if type(fcpxTable["$objects"][k]) == "table" then
					if fcpxTable["$objects"][k]["$classname"] ~= nil then
						if fcpxTable["$objects"][k]["$classname"] == "FFAnchoredCollection" then
							FFAnchoredCollectionID = k - 1
						end
					end
				end
			end
			if FFAnchoredCollectionID == nil then
				debugMessage("ERROR: Failed to get FFAnchoredCollectionID." .. errorFunction)
				return false
			end

			--------------------------------------------------------------------------------
			-- Find all FFAnchoredCollection's:
			--------------------------------------------------------------------------------
			local FFAnchoredCollectionTable = {}
			for k, v in pairs(fcpxTable["$objects"]) do
				if type(fcpxTable["$objects"][k]) == "table" then
					for a, b in pairs(fcpxTable["$objects"][k]) do
						if fcpxTable["$objects"][k][a] == FFAnchoredCollectionID then
							FFAnchoredCollectionTable[#FFAnchoredCollectionTable + 1] = fcpxTable["$objects"][k]
						end
						if type(fcpxTable["$objects"][k][a]) == "table" then
							for c, d in pairs(fcpxTable["$objects"][k][a]) do
								if fcpxTable["$objects"][k][a][c] == FFAnchoredCollectionID then
									FFAnchoredCollectionTable[#FFAnchoredCollectionTable + 1] = fcpxTable["$objects"][k]
								end
								if type(fcpxTable["$objects"][k][a][c]) == "table" then
									for e, f in pairs(fcpxTable["$objects"][k][a][c]) do
										if fcpxTable["$objects"][k][a][c][e] == FFAnchoredCollectionID then
											FFAnchoredCollectionTable[#FFAnchoredCollectionTable + 1] = fcpxTable["$objects"][k]
										end
									end
								end
							end
						end
					end
				end
			end
			if next(FFAnchoredCollectionTable) == nil then
				debugMessage("ERROR: Failed to get FFAnchoredCollectionTable." .. errorFunction)
				return false
			end

			--------------------------------------------------------------------------------
			-- Get the videoAngle:
			--------------------------------------------------------------------------------
			local videoAngle = nil
			for k, v in pairs(fcpxTable["$objects"]) do
				if type(fcpxTable["$objects"][k]) == "table" then
					if fcpxTable["$objects"][k]["videoAngle"] then
						videoAngle = fcpxTable["$objects"][k]["videoAngle"]
					end
				end
			end
			if videoAngle == nil then
				debugMessage("ERROR: Could not get videoAngle." .. errorFunction)
				return false
			end

			--------------------------------------------------------------------------------
			-- Get the videoAngle Reference:
			--------------------------------------------------------------------------------
			local videoAngleReference = fcpxTable["$objects"][videoAngle["CF$UID"] + 1]
			if videoAngleReference == nil then
				debugMessage("ERROR: Could not get videoAngleReference." .. errorFunction)
				return false
			end

			--------------------------------------------------------------------------------
			-- Match the FFAnchoredCollectionTable Video Angle with videoAngle:
			--------------------------------------------------------------------------------
			local result = nil
			for a, b in pairs(FFAnchoredCollectionTable) do
				local angleID = fcpxTable["$objects"][b["angleID"]["CF$UID"] + 1]
				if angleID ~= nil then
					if angleID == videoAngleReference then
						result = b["anchoredLane"]
					end
				end
			end
			if result == nil then
				debugMessage("ERROR: Failed to get anchoredLane." .. errorFunction)
				return false
			end

			--------------------------------------------------------------------------------
			-- Return Result:
			--------------------------------------------------------------------------------
			return result

		end

	--------------------------------------------------------------------------------
	-- MATCH FRAME THEN HIGHLIGHT FCPX BROWSER PLAYHEAD:
	--------------------------------------------------------------------------------
	function matchFrameThenHighlightFCPXBrowserPlayhead()

		--------------------------------------------------------------------------------
		-- Delete Any Highlights:
		--------------------------------------------------------------------------------
		deleteAllHighlights()

		--------------------------------------------------------------------------------
		-- Click on 'Reveal in Browser':
		--------------------------------------------------------------------------------
		if fcp:menuBar():isEnabled("File", "Reveal in Browser") then
			fcp:menuBar():selectMenu("File", "Reveal in Browser")
			highlightFCPXBrowserPlayhead()
		else
			dialog.displayErrorMessage("Failed to 'Reveal in Browser'.\n\nError occurred in matchFrameThenHighlightFCPXBrowserPlayhead().")
			return "Fail"
		end

	end

	--------------------------------------------------------------------------------
	-- FCPX SINGLE MATCH FRAME:
	--------------------------------------------------------------------------------
	function singleMatchFrame()

		--------------------------------------------------------------------------------
		-- Check the option is available in the current context
		--------------------------------------------------------------------------------
		if not fcp:menuBar():isEnabled("File", "Reveal in Browser") then
			return nil
		end

		--------------------------------------------------------------------------------
		-- Delete any pre-existing highlights:
		--------------------------------------------------------------------------------
		deleteAllHighlights()

		local libraries = fcp:libraries()
		local selectedClips


		--------------------------------------------------------------------------------
		-- Clear the selection first
		--------------------------------------------------------------------------------
		libraries:deselectAll()

		--------------------------------------------------------------------------------
		-- Trigger the menu item to reveal the clip
		--------------------------------------------------------------------------------
		fcp:menuBar():selectMenu("File", "Reveal in Browser")

		--------------------------------------------------------------------------------
		-- Give FCPX time to find the clip
		--------------------------------------------------------------------------------
		just.doUntil(function()
			selectedClips = libraries:selectedClipsUI()
			return selectedClips and #selectedClips > 0
		end)

		--------------------------------------------------------------------------------
		-- Get Check that there is exactly one Selected Clip
		--------------------------------------------------------------------------------
		if not selectedClips or #selectedClips ~= 1 then
			dialog.displayErrorMessage("Expected exactly 1 selected clip in the Libraries Browser.\n\nError occurred in singleMatchFrame().")
			return nil
		end

		--------------------------------------------------------------------------------
		-- Get Browser Playhead:
		--------------------------------------------------------------------------------
		local playhead = libraries:playhead()
		if not playhead:isShowing() then
			dialog.displayErrorMessage("Unable to find Browser Persistent Playhead.\n\nError occurred in singleMatchFrame().")
			return nil
		end

		--------------------------------------------------------------------------------
		-- Get Clip Name from the Viewer
		--------------------------------------------------------------------------------
		local clipName = fcp:viewer():getTitle()

		if clipName then
			--------------------------------------------------------------------------------
			-- Ensure the Search Bar is visible
			--------------------------------------------------------------------------------
			if not libraries:search():isShowing() then
				libraries:searchToggle():press()
			end

			--------------------------------------------------------------------------------
			-- Search for the title
			--------------------------------------------------------------------------------
			libraries:search():setValue(clipName)
		else
			debugMessage("Unable to find the clip title.")
		end

		--------------------------------------------------------------------------------
		-- Highlight Browser Playhead:
		--------------------------------------------------------------------------------
		highlightFCPXBrowserPlayhead()
	end

--------------------------------------------------------------------------------
-- COLOR BOARD RELATED:
--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- COLOR BOARD - PUCK SELECTION:
	--------------------------------------------------------------------------------
	function colorBoardSelectPuck(aspect, property, whichDirection)

		--------------------------------------------------------------------------------
		-- Delete any pre-existing highlights:
		--------------------------------------------------------------------------------
		deleteAllHighlights()

		--------------------------------------------------------------------------------
		-- Show the Color Board with the correct panel
		--------------------------------------------------------------------------------
		local colorBoard = fcp:colorBoard()

		--------------------------------------------------------------------------------
		-- Show the Color Board if it's hidden:
		--------------------------------------------------------------------------------
		if not colorBoard:isShowing() then colorBoard:show() end

		if not colorBoard:isActive() then
			dialog.displayNotification(i18n("pleaseSelectSingleClipInTimeline"))
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- If a Direction is specified:
		--------------------------------------------------------------------------------
		if whichDirection ~= nil then

			--------------------------------------------------------------------------------
			-- Get shortcut key from plist, press and hold if required:
			--------------------------------------------------------------------------------
			mod.releaseColorBoardDown = false
			timer.doUntil(function() return mod.releaseColorBoardDown end, function()
				if whichDirection == "up" then
					colorBoard:shiftPercentage(aspect, property, 1)
				elseif whichDirection == "down" then
					colorBoard:shiftPercentage(aspect, property, -1)
				elseif whichDirection == "left" then
					colorBoard:shiftAngle(aspect, property, -1)
				elseif whichDirection == "right" then
					colorBoard:shiftAngle(aspect, property, 1)
				end
			end, eventtap.keyRepeatInterval())
		else -- just select the puck
			colorBoard:selectPuck(aspect, property)
		end
	end

		--------------------------------------------------------------------------------
		-- COLOR BOARD - RELEASE KEYPRESS:
		--------------------------------------------------------------------------------
		function colorBoardSelectPuckRelease()
			mod.releaseColorBoardDown = true
		end

	--------------------------------------------------------------------------------
	-- COLOR BOARD - PUCK CONTROL VIA MOUSE:
	--------------------------------------------------------------------------------
	function colorBoardMousePuck(aspect, property)
		--------------------------------------------------------------------------------
		-- Stop Existing Color Pucker:
		--------------------------------------------------------------------------------
		if mod.colorPucker then
			mod.colorPucker:stop()
		end

		--------------------------------------------------------------------------------
		-- Delete any pre-existing highlights:
		--------------------------------------------------------------------------------
		deleteAllHighlights()

		colorBoard = fcp:colorBoard()

		--------------------------------------------------------------------------------
		-- Show the Color Board if it's hidden:
		--------------------------------------------------------------------------------
		if not colorBoard:isShowing() then colorBoard:show() end

		if not colorBoard:isActive() then
			dialog.displayNotification(i18n("pleaseSelectSingleClipInTimeline"))
			return "Failed"
		end

		mod.colorPucker = colorBoard:startPucker(aspect, property)
	end

		--------------------------------------------------------------------------------
		-- COLOR BOARD - RELEASE MOUSE KEYPRESS:
		--------------------------------------------------------------------------------
		function colorBoardMousePuckRelease()
			if mod.colorPucker then
				mod.colorPucker:stop()
				mod.colorPicker = nil
			end
		end

--------------------------------------------------------------------------------
-- EFFECTS/TRANSITIONS/TITLES/GENERATOR RELATED:
--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- TRANSITIONS SHORTCUT PRESSED:
	--------------------------------------------------------------------------------
	function transitionsShortcut(whichShortcut)

		--------------------------------------------------------------------------------
		-- Get settings:
		--------------------------------------------------------------------------------
		local currentLanguage = fcp:getCurrentLanguage()
		local currentShortcut = nil
		if whichShortcut == 1 then
			currentShortcut = settings.get("fcpxHacks." .. currentLanguage .. ".transitionsShortcutOne")
		elseif whichShortcut == 2 then
			currentShortcut = settings.get("fcpxHacks." .. currentLanguage .. ".transitionsShortcutTwo")
		elseif whichShortcut == 3 then
			currentShortcut = settings.get("fcpxHacks." .. currentLanguage .. ".transitionsShortcutThree")
		elseif whichShortcut == 4 then
			currentShortcut = settings.get("fcpxHacks." .. currentLanguage .. ".transitionsShortcutFour")
		elseif whichShortcut == 5 then
			currentShortcut = settings.get("fcpxHacks." .. currentLanguage .. ".transitionsShortcutFive")
		elseif tostring(whichShortcut) ~= "" then
			currentShortcut = tostring(whichShortcut)
		end

		if currentShortcut == nil then
			dialog.displayMessage(i18n("noTransitionShortcut"))
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Save the Effects Browser layout:
		--------------------------------------------------------------------------------
		local effects = fcp:effects()
		local effectsLayout = effects:saveLayout()

		--------------------------------------------------------------------------------
		-- Get Transitions Browser:
		--------------------------------------------------------------------------------
		local transitions = fcp:transitions()
		local transitionsShowing = transitions:isShowing()
		local transitionsLayout = transitions:saveLayout()

		--------------------------------------------------------------------------------
		-- Make sure Transitions panel is open:
		--------------------------------------------------------------------------------
		transitions:show()

		--------------------------------------------------------------------------------
		-- Make sure "Installed Transitions" is selected:
		--------------------------------------------------------------------------------
		transitions:showInstalledTransitions()

		--------------------------------------------------------------------------------
		-- Make sure there's nothing in the search box:
		--------------------------------------------------------------------------------
		transitions:search():clear()

		--------------------------------------------------------------------------------
		-- Click 'All':
		--------------------------------------------------------------------------------
		transitions:showAllTransitions()

		--------------------------------------------------------------------------------
		-- Perform Search:
		--------------------------------------------------------------------------------
		transitions:search():setValue(currentShortcut)

		--------------------------------------------------------------------------------
		-- Get the list of matching transitions
		--------------------------------------------------------------------------------
		local matches = transitions:currentItemsUI()
		if not matches or #matches == 0 then
			--------------------------------------------------------------------------------
			-- If Needed, Search Again Without Text Before First Dash:
			--------------------------------------------------------------------------------
			local index = string.find(currentShortcut, "-")
			if index ~= nil then
				local trimmedShortcut = string.sub(currentShortcut, index + 2)
				transitions:search():setValue(trimmedShortcut)

				matches = transitions:currentItemsUI()
				if not matches or #matches == 0 then
					dialog.displayErrorMessage("Unable to find a transition called '"..currentShortcut.."'.\n\nError occurred in transitionsShortcut().")
					return "Fail"
				end
			end
		end

		local transition = matches[1]

		--------------------------------------------------------------------------------
		-- Apply the selected Transition:
		--------------------------------------------------------------------------------
		hideTouchbar()

		transitions:applyItem(transition)

		-- TODO: HACK: This timer exists to  work around a mouse bug in Hammerspoon Sierra
		timer.doAfter(0.000001, function()
			showTouchbar()

			transitions:loadLayout(transitionsLayout)
			if effectsLayout then effects:loadLayout(effectsLayout) end
			if not transitionsShowing then transitions:hide() end
		end)
	end

	--------------------------------------------------------------------------------
	-- EFFECTS SHORTCUT PRESSED:
	--------------------------------------------------------------------------------
	function effectsShortcut(whichShortcut)

		--------------------------------------------------------------------------------
		-- Get settings:
		--------------------------------------------------------------------------------
		local currentLanguage = fcp:getCurrentLanguage()
		local currentShortcut = nil
		if whichShortcut == 1 then
			currentShortcut = settings.get("fcpxHacks." .. currentLanguage .. ".effectsShortcutOne")
		elseif whichShortcut == 2 then
			currentShortcut = settings.get("fcpxHacks." .. currentLanguage .. ".effectsShortcutTwo")
		elseif whichShortcut == 3 then
			currentShortcut = settings.get("fcpxHacks." .. currentLanguage .. ".effectsShortcutThree")
		elseif whichShortcut == 4 then
			currentShortcut = settings.get("fcpxHacks." .. currentLanguage .. ".effectsShortcutFour")
		elseif whichShortcut == 5 then
			currentShortcut = settings.get("fcpxHacks." .. currentLanguage .. ".effectsShortcutFive")
		else
			if tostring(whichShortcut) ~= "" then
				currentShortcut = tostring(whichShortcut)
			end
		end

		if currentShortcut == nil then
			dialog.displayMessage(i18n("noEffectShortcut"))
			showTouchbar()
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Save the Transitions Browser layout:
		--------------------------------------------------------------------------------
		local transitions = fcp:transitions()
		local transitionsLayout = transitions:saveLayout()

		--------------------------------------------------------------------------------
		-- Get Effects Browser:
		--------------------------------------------------------------------------------
		local effects = fcp:effects()
		local effectsShowing = effects:isShowing()
		local effectsLayout = effects:saveLayout()

		--------------------------------------------------------------------------------
		-- Make sure panel is open:
		--------------------------------------------------------------------------------
		effects:show()

		--------------------------------------------------------------------------------
		-- Make sure "Installed Effects" is selected:
		--------------------------------------------------------------------------------
		effects:showInstalledEffects()

		--------------------------------------------------------------------------------
		-- Make sure there's nothing in the search box:
		--------------------------------------------------------------------------------
		effects:search():clear()

		--------------------------------------------------------------------------------
		-- Click 'All':
		--------------------------------------------------------------------------------
		effects:showAllTransitions()

		--------------------------------------------------------------------------------
		-- Perform Search:
		--------------------------------------------------------------------------------
		effects:search():setValue(currentShortcut)

		--------------------------------------------------------------------------------
		-- Get the list of matching effects
		--------------------------------------------------------------------------------
		local matches = effects:currentItemsUI()
		if not matches or #matches == 0 then
			--------------------------------------------------------------------------------
			-- If Needed, Search Again Without Text Before First Dash:
			--------------------------------------------------------------------------------
			local index = string.find(currentShortcut, "-")
			if index ~= nil then
				local trimmedShortcut = string.sub(currentShortcut, index + 2)
				effects:search():setValue(trimmedShortcut)

				matches = effects:currentItemsUI()
				if not matches or #matches == 0 then
					dialog.displayErrorMessage("Unable to find a transition called '"..currentShortcut.."'.\n\nError occurred in effectsShortcut().")
					return "Fail"
				end
			end
		end

		local effect = matches[1]

		--------------------------------------------------------------------------------
		-- Apply the selected Transition:
		--------------------------------------------------------------------------------
		hideTouchbar()

		effects:applyItem(effect)

		-- TODO: HACK: This timer exists to  work around a mouse bug in Hammerspoon Sierra
		timer.doAfter(0.000001, function()
			showTouchbar()

			effects:loadLayout(effectsLayout)
			if transitionsLayout then transitions:loadLayout(transitionsLayout) end
			if not effectsShowing then effects:hide() end
		end)

	end

	--------------------------------------------------------------------------------
	-- TITLES SHORTCUT PRESSED:
	--------------------------------------------------------------------------------
	function titlesShortcut(whichShortcut)

		--------------------------------------------------------------------------------
		-- Get settings:
		--------------------------------------------------------------------------------
		local currentLanguage = fcp:getCurrentLanguage()
		local currentShortcut = nil
		if whichShortcut == 1 then
			currentShortcut = settings.get("fcpxHacks." .. currentLanguage .. ".titlesShortcutOne")
		elseif whichShortcut == 2 then
			currentShortcut = settings.get("fcpxHacks." .. currentLanguage .. ".titlesShortcutTwo")
		elseif whichShortcut == 3 then
			currentShortcut = settings.get("fcpxHacks." .. currentLanguage .. ".titlesShortcutThree")
		elseif whichShortcut == 4 then
			currentShortcut = settings.get("fcpxHacks." .. currentLanguage .. ".titlesShortcutFour")
		elseif whichShortcut == 5 then
			currentShortcut = settings.get("fcpxHacks." .. currentLanguage .. ".titlesShortcutFive")
		else
			if tostring(whichShortcut) ~= "" then
				currentShortcut = tostring(whichShortcut)
			end
		end

		if currentShortcut == nil then
			dialog.displayMessage(i18n("noTitleShortcut"))
			showTouchbar()
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Save the main Browser layout:
		--------------------------------------------------------------------------------
		local browser = fcp:browser()
		local browserLayout = browser:saveLayout()

		--------------------------------------------------------------------------------
		-- Get Titles Browser:
		--------------------------------------------------------------------------------
		local generators = fcp:generators()
		local generatorsShowing = generators:isShowing()
		local generatorsLayout = generators:saveLayout()

		--------------------------------------------------------------------------------
		-- Make sure panel is open:
		--------------------------------------------------------------------------------
		generators:show()

		--------------------------------------------------------------------------------
		-- Make sure there's nothing in the search box:
		--------------------------------------------------------------------------------
		generators:search():clear()

		--------------------------------------------------------------------------------
		-- Click 'All':
		--------------------------------------------------------------------------------
		generators:showAllTitles()

		--------------------------------------------------------------------------------
		-- Make sure "Installed Titles" is selected:
		--------------------------------------------------------------------------------
		generators:showInstalledTitles()

		--------------------------------------------------------------------------------
		-- Perform Search:
		--------------------------------------------------------------------------------
		generators:search():setValue(currentShortcut)

		--------------------------------------------------------------------------------
		-- Get the list of matching effects
		--------------------------------------------------------------------------------
		local matches = generators:currentItemsUI()
		if not matches or #matches == 0 then
			--------------------------------------------------------------------------------
			-- If Needed, Search Again Without Text Before First Dash:
			--------------------------------------------------------------------------------
			local index = string.find(currentShortcut, "-")
			if index ~= nil then
				local trimmedShortcut = string.sub(currentShortcut, index + 2)
				effects:search():setValue(trimmedShortcut)

				matches = generators:currentItemsUI()
				if not matches or #matches == 0 then
					dialog.displayErrorMessage("Unable to find a transition called '"..currentShortcut.."'.\n\nError occurred in effectsShortcut().")
					return "Fail"
				end
			end
		end

		local generator = matches[1]

		--------------------------------------------------------------------------------
		-- Apply the selected Transition:
		--------------------------------------------------------------------------------
		hideTouchbar()

		generators:applyItem(generator)

		-- TODO: HACK: This timer exists to  work around a mouse bug in Hammerspoon Sierra
		timer.doAfter(0.000001, function()
			showTouchbar()

			generators:loadLayout(generatorsLayout)
			if browserLayout then browser:loadLayout(browserLayout) end
			if not generatorsShowing then generators:hide() end
		end)

	end

	--------------------------------------------------------------------------------
	-- GENERATORS SHORTCUT PRESSED:
	--------------------------------------------------------------------------------
	function generatorsShortcut(whichShortcut)

		--------------------------------------------------------------------------------
		-- Hide the Touch Bar:
		--------------------------------------------------------------------------------
		hideTouchbar()

		--------------------------------------------------------------------------------
		-- Get settings:
		--------------------------------------------------------------------------------
		local currentLanguage = fcp:getCurrentLanguage()
		local currentShortcut = nil
		if whichShortcut == 1 then
			currentShortcut = settings.get("fcpxHacks." .. currentLanguage .. ".generatorsShortcutOne")
		elseif whichShortcut == 2 then
			currentShortcut = settings.get("fcpxHacks." .. currentLanguage .. ".generatorsShortcutTwo")
		elseif whichShortcut == 3 then
			currentShortcut = settings.get("fcpxHacks." .. currentLanguage .. ".generatorsShortcutThree")
		elseif whichShortcut == 4 then
			currentShortcut = settings.get("fcpxHacks." .. currentLanguage .. ".generatorsShortcutFour")
		elseif whichShortcut == 5 then
			currentShortcut = settings.get("fcpxHacks." .. currentLanguage .. ".generatorsShortcutFive")
		else
			if tostring(whichShortcut) ~= "" then
				currentShortcut = tostring(whichShortcut)
			end
		end

		if currentShortcut == nil then
			dialog.displayMessage(i18n("noGeneratorShortcut"))
			showTouchbar()
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Save the main Browser layout:
		--------------------------------------------------------------------------------
		local browser = fcp:browser()
		local browserLayout = browser:saveLayout()

		--------------------------------------------------------------------------------
		-- Get Titles Browser:
		--------------------------------------------------------------------------------
		local generators = fcp:generators()
		local generatorsShowing = generators:isShowing()
		local generatorsLayout = generators:saveLayout()

		--------------------------------------------------------------------------------
		-- Make sure panel is open:
		--------------------------------------------------------------------------------
		generators:show()

		--------------------------------------------------------------------------------
		-- Make sure there's nothing in the search box:
		--------------------------------------------------------------------------------
		generators:search():clear()

		--------------------------------------------------------------------------------
		-- Click 'All':
		--------------------------------------------------------------------------------
		generators:showAllGenerators()

		--------------------------------------------------------------------------------
		-- Make sure "Installed Titles" is selected:
		--------------------------------------------------------------------------------
		generators:showInstalledGenerators()

		--------------------------------------------------------------------------------
		-- Perform Search:
		--------------------------------------------------------------------------------
		generators:search():setValue(currentShortcut)

		--------------------------------------------------------------------------------
		-- Get the list of matching effects
		--------------------------------------------------------------------------------
		local matches = generators:currentItemsUI()
		if not matches or #matches == 0 then
			--------------------------------------------------------------------------------
			-- If Needed, Search Again Without Text Before First Dash:
			--------------------------------------------------------------------------------
			local index = string.find(currentShortcut, "-")
			if index ~= nil then
				local trimmedShortcut = string.sub(currentShortcut, index + 2)
				effects:search():setValue(trimmedShortcut)

				matches = generators:currentItemsUI()
				if not matches or #matches == 0 then
					dialog.displayErrorMessage("Unable to find a transition called '"..currentShortcut.."'.\n\nError occurred in effectsShortcut().")
					return "Fail"
				end
			end
		end

		local generator = matches[1]

		--------------------------------------------------------------------------------
		-- Apply the selected Transition:
		--------------------------------------------------------------------------------
		hideTouchbar()

		generators:applyItem(generator)

		-- TODO: HACK: This timer exists to  work around a mouse bug in Hammerspoon Sierra
		timer.doAfter(0.000001, function()
			showTouchbar()

			generators:loadLayout(generatorsLayout)
			if browserLayout then browser:loadLayout(browserLayout) end
			if not generatorsShowing then generators:hide() end
		end)

	end

--------------------------------------------------------------------------------
-- OTHER SHORTCUTS:
--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- CHANGE TIMELINE CLIP HEIGHT:
	--------------------------------------------------------------------------------
	function changeTimelineClipHeight(direction)

		--------------------------------------------------------------------------------
		-- Prevent multiple keypresses:
		--------------------------------------------------------------------------------
		if mod.changeTimelineClipHeightAlreadyInProgress then return end
		mod.changeTimelineClipHeightAlreadyInProgress = true

		--------------------------------------------------------------------------------
		-- Delete any pre-existing highlights:
		--------------------------------------------------------------------------------
		deleteAllHighlights()

		--------------------------------------------------------------------------------
		-- Change Value of Zoom Slider:
		--------------------------------------------------------------------------------
		shiftClipHeight(direction)

		--------------------------------------------------------------------------------
		-- Keep looping it until the key is released.
		--------------------------------------------------------------------------------
		timer.doUntil(function() return not mod.changeTimelineClipHeightAlreadyInProgress end, function()
			shiftClipHeight(direction)
		end, eventtap.keyRepeatInterval())
	end

		--------------------------------------------------------------------------------
		-- SHIFT CLIP HEIGHT:
		--------------------------------------------------------------------------------
		function shiftClipHeight(direction)
			--------------------------------------------------------------------------------
			-- Find the Timeline Appearance Button:
			--------------------------------------------------------------------------------
			local appearance = fcp:timeline():toolbar():appearance()
			appearance:show()
			if direction == "up" then
				appearance:clipHeight():increment()
			else
				appearance:clipHeight():decrement()
			end
		end

		--------------------------------------------------------------------------------
		-- CHANGE TIMELINE CLIP HEIGHT RELEASE:
		--------------------------------------------------------------------------------
		function changeTimelineClipHeightRelease()
			mod.changeTimelineClipHeightAlreadyInProgress = false
			fcp:timeline():toolbar():appearance():hide()
		end

	--------------------------------------------------------------------------------
	-- SELECT CLIP AT LANE:
	--------------------------------------------------------------------------------
	function selectClipAtLane(whichLane)
		local content = fcp:timeline():contents()
		local playheadX = content:playhead():getPosition()

		local clips = content:clipsUI(false, function(clip)
			local frame = clip:frame()
			return playheadX >= frame.x and playheadX < (frame.x + frame.w)
		end)

		if clips == nil then
			debugMessage("No clips detected in selectClipAtLane().")
			return false
		end

		if whichLane > #clips then
			return false
		end

		--------------------------------------------------------------------------------
		-- Sort the table:
		--------------------------------------------------------------------------------
		table.sort(clips, function(a, b) return a:position().y > b:position().y end)

		content:selectClip(clips[whichLane])

		return true
	end

	--------------------------------------------------------------------------------
	-- MENU ITEM SHORTCUT:
	--------------------------------------------------------------------------------
	function menuItemShortcut(i, x, y, z)

		local fcpxElements = ax.applicationElement(fcp:application())

		local whichMenuBar = nil
		for i=1, fcpxElements:attributeValueCount("AXChildren") do
			if fcpxElements[i]:attributeValue("AXRole") == "AXMenuBar" then
				whichMenuBar = i
			end
		end

		if whichMenuBar == nil then
			displayErrorMessage("Failed to find menu bar.\n\nError occurred in menuItemShortcut().")
			return
		end

		if i ~= "" and x ~= "" and y == "" and z == "" then
			fcpxElements[whichMenuBar][i][1][x]:performAction("AXPress")
		elseif i ~= "" and x ~= "" and y ~= "" and z == "" then
			fcpxElements[whichMenuBar][i][1][x][1][y]:performAction("AXPress")
		elseif i ~= "" and x ~= "" and y ~= "" and z ~= "" then
			fcpxElements[whichMenuBar][i][1][x][1][y][1][z]:performAction("AXPress")
		end

	end

	--------------------------------------------------------------------------------
	-- TOGGLE TOUCH BAR:
	--------------------------------------------------------------------------------
	function toggleTouchBar()

		--------------------------------------------------------------------------------
		-- Check for compatibility:
		--------------------------------------------------------------------------------
		if not touchBarSupported then
			dialog.displayMessage(i18n("touchBarError"))
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Get Settings:
		--------------------------------------------------------------------------------
		local displayTouchBar = settings.get("fcpxHacks.displayTouchBar") or false

		--------------------------------------------------------------------------------
		-- Toggle Touch Bar:
		--------------------------------------------------------------------------------
		setTouchBarLocation()
		if fcp:isRunning() then
			mod.touchBarWindow:toggle()
		end

		--------------------------------------------------------------------------------
		-- Update Settings:
		--------------------------------------------------------------------------------
		settings.set("fcpxHacks.displayTouchBar", not displayTouchBar)

		--------------------------------------------------------------------------------
		-- Refresh Menubar:
		--------------------------------------------------------------------------------
		refreshMenuBar()

	end

	--------------------------------------------------------------------------------
	-- CUT AND SWITCH MULTI-CAM:
	--------------------------------------------------------------------------------
	function cutAndSwitchMulticam(whichMode, whichAngle)

		if whichMode == "Audio" then
			if not fcp:performShortcut("MultiAngleEditStyleAudio") then
				dialog.displayErrorMessage("We were unable to trigger the 'Cut/Switch Multicam Audio Only' Shortcut.\n\nPlease make sure this shortcut is allocated in the Command Editor.\n\nError Occured in cutAndSwitchMulticam().")
				return "Failed"
			end
		end

		if whichMode == "Video" then
			if not fcp:performShortcut("MultiAngleEditStyleVideo") then
				dialog.displayErrorMessage("We were unable to trigger the 'Cut/Switch Multicam Video Only' Shortcut.\n\nPlease make sure this shortcut is allocated in the Command Editor.\n\nError Occured in cutAndSwitchMulticam().")
				return "Failed"
			end
		end

		if whichMode == "Both" then
			if not fcp:performShortcut("MultiAngleEditStyleAudioVideo") then
				dialog.displayErrorMessage("We were unable to trigger the 'Cut/Switch Multicam Audio and Video' Shortcut.\n\nPlease make sure this shortcut is allocated in the Command Editor.\n\nError Occured in cutAndSwitchMulticam().")
				return "Failed"
			end
		end

		if not fcp:performShortcut("CutSwitchAngle" .. tostring(string.format("%02d", whichAngle))) then
			dialog.displayErrorMessage("We were unable to trigger the 'Cut and Switch to Viewer Angle " .. tostring(whichAngle) .. "' Shortcut.\n\nPlease make sure this shortcut is allocated in the Command Editor.\n\nError Occured in cutAndSwitchMulticam().")
			return "Failed"
		end

	end

	--------------------------------------------------------------------------------
	-- MOVE TO PLAYHEAD:
	--------------------------------------------------------------------------------
	function moveToPlayhead()

		local enableClipboardHistory = settings.get("fcpxHacks.enableClipboardHistory") or false

		if enableClipboardHistory then
			clipboard.stopWatching()
		end

		if not fcp:performShortcut("Cut") then
			dialog.displayErrorMessage("Failed to trigger the 'Cut' Shortcut.\n\nError occurred in moveToPlayhead().")
			goto moveToPlayheadEnd
		end

		if not fcp:performShortcut("Paste") then
			dialog.displayErrorMessage("Failed to trigger the 'Paste' Shortcut.\n\nError occurred in moveToPlayhead().")
			goto moveToPlayheadEnd
		end

		::moveToPlayheadEnd::
		if enableClipboardHistory then
			timer.doAfter(2, function() clipboard.startWatching() end)
		end

	end

	--------------------------------------------------------------------------------
	-- HIGHLIGHT FINAL CUT PRO BROWSER PLAYHEAD:
	--------------------------------------------------------------------------------
	function highlightFCPXBrowserPlayhead()

		--------------------------------------------------------------------------------
		-- Delete any pre-existing highlights:
		--------------------------------------------------------------------------------
		deleteAllHighlights()

		--------------------------------------------------------------------------------
		-- Get Browser Persistent Playhead:
		--------------------------------------------------------------------------------
		local playhead = fcp:libraries():playhead()
		if playhead:isShowing() then

			--------------------------------------------------------------------------------
			-- Playhead Position:
			--------------------------------------------------------------------------------
			local frame = playhead:getFrame()

			--------------------------------------------------------------------------------
			-- Highlight Mouse:
			--------------------------------------------------------------------------------
			mouseHighlight(frame.x, frame.y, frame.w, frame.h)

		end

	end

		--------------------------------------------------------------------------------
		-- HIGHLIGHT MOUSE IN FCPX:
		--------------------------------------------------------------------------------
		function mouseHighlight(mouseHighlightX, mouseHighlightY, mouseHighlightW, mouseHighlightH)

			--------------------------------------------------------------------------------
			-- Delete Previous Highlights:
			--------------------------------------------------------------------------------
			deleteAllHighlights()

			--------------------------------------------------------------------------------
			-- Get Sizing Preferences:
			--------------------------------------------------------------------------------
			local displayHighlightShape = nil
			displayHighlightShape = settings.get("fcpxHacks.displayHighlightShape")
			if displayHighlightShape == nil then displayHighlightShape = "Rectangle" end

			--------------------------------------------------------------------------------
			-- Get Highlight Colour Preferences:
			--------------------------------------------------------------------------------
			local displayHighlightColour = settings.get("fcpxHacks.displayHighlightColour") or "Red"
			if displayHighlightColour == "Red" then 	displayHighlightColour = {["red"]=1,["blue"]=0,["green"]=0,["alpha"]=1} 	end
			if displayHighlightColour == "Blue" then 	displayHighlightColour = {["red"]=0,["blue"]=1,["green"]=0,["alpha"]=1}		end
			if displayHighlightColour == "Green" then 	displayHighlightColour = {["red"]=0,["blue"]=0,["green"]=1,["alpha"]=1}		end
			if displayHighlightColour == "Yellow" then 	displayHighlightColour = {["red"]=1,["blue"]=0,["green"]=1,["alpha"]=1}		end
			if displayHighlightColour == "Custom" then
				local displayHighlightCustomColour = settings.get("fcpxHacks.displayHighlightCustomColour")
				displayHighlightColour = {red=displayHighlightCustomColour["red"],blue=displayHighlightCustomColour["blue"],green=displayHighlightCustomColour["green"],alpha=1}
			end

			--------------------------------------------------------------------------------
			-- Highlight the FCPX Browser Playhead:
			--------------------------------------------------------------------------------
			if displayHighlightShape == "Rectangle" then
				mod.browserHighlight = drawing.rectangle(geometry.rect(mouseHighlightX, mouseHighlightY, mouseHighlightW, mouseHighlightH - 12))
			end
			if displayHighlightShape == "Circle" then
				mod.browserHighlight = drawing.circle(geometry.rect((mouseHighlightX-(mouseHighlightH/2)+10), mouseHighlightY, mouseHighlightH-12, mouseHighlightH-12))
			end
			if displayHighlightShape == "Diamond" then
				mod.browserHighlight = drawing.circle(geometry.rect(mouseHighlightX, mouseHighlightY, mouseHighlightW, mouseHighlightH - 12))
			end
			mod.browserHighlight:setStrokeColor(displayHighlightColour)
							    :setFill(false)
							    :setStrokeWidth(5)
							    :bringToFront(true)
							    :show()

			--------------------------------------------------------------------------------
			-- Set a timer to delete the circle after 3 seconds:
			--------------------------------------------------------------------------------
			local highlightPlayheadTime = settings.get("fcpxHacks.highlightPlayheadTime")
			mod.browserHighlightTimer = timer.doAfter(highlightPlayheadTime, function() mod.browserHighlight:delete() end)

		end

	--------------------------------------------------------------------------------
	-- SELECT ALL TIMELINE CLIPS IN SPECIFIC DIRECTION:
	--------------------------------------------------------------------------------
	function selectAllTimelineClips(forwards)

		local content = fcp:timeline():contents()
		local playheadX = content:playhead():getPosition()

		local clips = content:clipsUI(false, function(clip)
			local frame = clip:frame()
			if forwards then
				return playheadX <= frame.x
			else
				return playheadX >= frame.x
			end
		end)

		if clips == nil then
			displayErrorMessage("No clips could be detected.\n\nError occurred in selectAllTimelineClips().")
			return false
		end

		content:selectClips(clips)

		return true

	end

--------------------------------------------------------------------------------
-- BATCH EXPORT:
--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- BATCH EXPORT FROM BROWSER:
	--------------------------------------------------------------------------------
	function batchExport()

		--------------------------------------------------------------------------------
		-- Set Custom Export Path (or Default to Desktop):
		--------------------------------------------------------------------------------
		local batchExportDestinationFolder = settings.get("fcpxHacks.batchExportDestinationFolder")
		local NSNavLastRootDirectory = fcp:getPreference("NSNavLastRootDirectory")
		local exportPath = "~/Desktop"
		if batchExportDestinationFolder ~= nil then
			 if tools.doesDirectoryExist(batchExportDestinationFolder) then
				exportPath = batchExportDestinationFolder
			 end
		else
			if tools.doesDirectoryExist(NSNavLastRootDirectory) then
				exportPath = NSNavLastRootDirectory
			end
		end

		--------------------------------------------------------------------------------
		-- Destination Preset:
		--------------------------------------------------------------------------------
		local destinationPreset = settings.get("fcpxHacks.batchExportDestinationPreset")
		if destinationPreset == nil then

			destinationPreset = fcp:menuBar():findMenuUI("File", "Share", function(menuItem)
				return menuItem:attributeValue("AXMenuItemCmdChar") ~= nil
			end):attributeValue("AXTitle")

			if destinationPreset == nil then
				displayErrorMessage(i18n("batchExportNoDestination"))
				return false
			else
				-- Remove (default) text:
				local firstBracket = string.find(destinationPreset, " %(", 1)
				if firstBracket == nil then
					firstBracket = string.find(destinationPreset, "（", 1)
				end
				destinationPreset = string.sub(destinationPreset, 1, firstBracket - 1)
			end

		end

		--------------------------------------------------------------------------------
		-- Replace Existing Files Option:
		--------------------------------------------------------------------------------
		local replaceExisting = settings.get("fcpxHacks.batchExportReplaceExistingFiles")

		--------------------------------------------------------------------------------
		-- Delete All Highlights:
		--------------------------------------------------------------------------------
		deleteAllHighlights()

		local libraries = fcp:browser():libraries()

		if not libraries:isShowing() then
			dialog.displayErrorMessage(i18n("batchExportEnableBrowser"))
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Check if we have any currently-selected clips:
		--------------------------------------------------------------------------------
		local clips = libraries:selectedClipsUI()

		if libraries:sidebar():isFocused() then
			--------------------------------------------------------------------------------
			-- Use All Clips:
			--------------------------------------------------------------------------------
			clips = libraries:clipsUI()
		end

		local batchExportSucceeded = false
		if clips and #clips > 0 then

			--------------------------------------------------------------------------------
			-- Display Dialog:
			--------------------------------------------------------------------------------
			local countText = " "
			if #clips > 1 then countText = " " .. tostring(#clips) .. " " end
			local replaceFilesMessage = ""
			if replaceExisting then
				replaceFilesMessage = i18n("batchExportReplaceYes")
			else
				replaceFilesMessage = i18n("batchExportReplaceNo")
			end
			local result = dialog.displayMessage(i18n("batchExportCheckPath", {count=countText, replace=replaceFilesMessage, path=exportPath, preset=destinationPreset, item=i18n("item", {count=#clips})}), {i18n("buttonContinueBatchExport"), i18n("cancel")})
			if result == nil then return end

			--------------------------------------------------------------------------------
			-- Export the clips:
			--------------------------------------------------------------------------------
			batchExportSucceeded = batchExportClips(libraries, clips, exportPath, destinationPreset, replaceExisting)

		else
			--------------------------------------------------------------------------------
			-- No Clips are Available:
			--------------------------------------------------------------------------------
			dialog.displayErrorMessage(i18n("batchExportNoClipsSelected"))
		end

		--------------------------------------------------------------------------------
		-- Batch Export Complete:
		--------------------------------------------------------------------------------
		if batchExportSucceeded then
			dialog.displayMessage(i18n("batchExportComplete"), {i18n("done")})
		end

	end

		--------------------------------------------------------------------------------
		-- BATCH EXPORT CLIPS:
		--------------------------------------------------------------------------------
		function batchExportClips(libraries, clips, exportPath, destinationPreset, replaceExisting)

			local errorFunction = " Error occurred in batchExportClips()."
			local firstTime = true
			for i,clip in ipairs(clips) do

				--------------------------------------------------------------------------------
				-- Select Item:
				--------------------------------------------------------------------------------
				libraries:selectClip(clip)

				--------------------------------------------------------------------------------
				-- Trigger Export:
				--------------------------------------------------------------------------------
				if not selectShare(destinationPreset) then
					dialog.displayErrorMessage("Could not trigger Share Menu Item." .. errorFunction)
					return false
				end

				--------------------------------------------------------------------------------
				-- Wait for Export Dialog to open:
				--------------------------------------------------------------------------------
				local exportDialog = fcp:exportDialog()
				if not just.doUntil(function() return exportDialog:isShowing() end) then
					dialog.displayErrorMessage("Failed to open the 'Export' window." .. errorFunction)
					return false
				end
				exportDialog:pressNext()

				--------------------------------------------------------------------------------
				-- If 'Next' has been clicked (as opposed to 'Share'):
				--------------------------------------------------------------------------------
				local saveSheet = exportDialog:saveSheet()
				if exportDialog:isShowing() then

					--------------------------------------------------------------------------------
					-- Click 'Save' on the save sheet:
					--------------------------------------------------------------------------------
					if not just.doUntil(function() return saveSheet:isShowing() end) then
						dialog.displayErrorMessage("Failed to open the 'Save' window." .. errorFunction)
						return false
					end

					--------------------------------------------------------------------------------
					-- Set Custom Export Path (or Default to Desktop):
					--------------------------------------------------------------------------------
					if firstTime then
						saveSheet:setPath(exportPath)
						firstTime = false
					end
					saveSheet:pressSave()

				end

				--------------------------------------------------------------------------------
				-- Make sure Save Window is closed:
				--------------------------------------------------------------------------------
				while saveSheet:isShowing() do
					local replaceAlert = saveSheet:replaceAlert()
					if replaceExisting and replaceAlert:isShowing() then
						replaceAlert:pressReplace()
					else
						replaceAlert:pressCancel()

						local originalFilename = saveSheet:filename():getValue()
						if originalFilename == nil then
							dialog.displayErrorMessage("Failed to get the original Filename." .. errorFunction)
							return false
						end

						local newFilename = tools.incrementFilename(originalFilename)

						saveSheet:filename():setValue(newFilename)
						saveSheet:pressSave()
					end
				end

			end
			return true
		end

		--------------------------------------------------------------------------------
		-- Trigger Export:
		--------------------------------------------------------------------------------
		function selectShare(destinationPreset)
			return fcp:menuBar():selectMenu("File", "Share", function(menuItem)
				if destinationPreset == nil then
					return menuItem:attributeValue("AXMenuItemCmdChar") ~= nil
				else
					local title = menuItem:attributeValue("AXTitle")
					return title and string.find(title, destinationPreset) ~= nil
				end
			end)

		end



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------





--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                     C O M M O N    F U N C T I O N S                       --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- GENERAL:
--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- NINJA PASTEBOARD COPY:
	--------------------------------------------------------------------------------
	function ninjaPasteboardCopy()

		local errorFunction = " Error occurred in ninjaPasteboardCopy()."

		--------------------------------------------------------------------------------
		-- Variables:
		--------------------------------------------------------------------------------
		local ninjaPasteboardCopyError = false
		local finalCutProClipboardUTI = fcp:getPasteboardUTI()
		local enableClipboardHistory = settings.get("fcpxHacks.enableClipboardHistory") or false

		--------------------------------------------------------------------------------
		-- Stop Watching Clipboard:
		--------------------------------------------------------------------------------
		if enableClipboardHistory then clipboard.stopWatching() end

		--------------------------------------------------------------------------------
		-- Save Current Clipboard Contents for later:
		--------------------------------------------------------------------------------
		local originalClipboard = pasteboard.readDataForUTI(finalCutProClipboardUTI)

		--------------------------------------------------------------------------------
		-- Trigger 'copy' from Menubar:
		--------------------------------------------------------------------------------
		local menuBar = fcp:menuBar()
		if menuBar:isEnabled("Edit", "Copy") then
			menuBar:selectMenu("Edit", "Copy")
		else
			debugMessage("ERROR: Failed to select Copy from Menubar." .. errorFunction)
			if enableClipboardHistory then clipboard.startWatching() end
			return false
		end

		--------------------------------------------------------------------------------
		-- Wait until something new is actually on the Pasteboard:
		--------------------------------------------------------------------------------
		local newClipboard = nil
		just.doUntil(function()
			newClipboard = pasteboard.readDataForUTI(finalCutProClipboardUTI)
			if newClipboard ~= originalClipboard then
				return true
			end
		end, 30, 0.5)
		if newClipboard == nil then
			debugMessage("ERROR: Failed to get new clipboard contents." .. errorFunction)
			if enableClipboardHistory then clipboard.startWatching() end
			return false
		end

		--------------------------------------------------------------------------------
		-- Restore Original Clipboard Contents:
		--------------------------------------------------------------------------------
		if originalClipboard ~= nil then
			local result = pasteboard.writeDataForUTI(finalCutProClipboardUTI, originalClipboard)
			if not result then
				debugMessage("ERROR: Failed to restore original Clipboard item." .. errorFunction)
				if enableClipboardHistory then clipboard.startWatching() end
				return false
			end
		end

		--------------------------------------------------------------------------------
		-- Start Watching Clipboard:
		--------------------------------------------------------------------------------
		if enableClipboardHistory then clipboard.startWatching() end

		--------------------------------------------------------------------------------
		-- Return New Clipboard:
		--------------------------------------------------------------------------------
		return true, newClipboard

	end

	--------------------------------------------------------------------------------
	-- EMAIL BUG REPORT:
	--------------------------------------------------------------------------------
	function emailBugReport()
		local mailer = sharing.newShare("com.apple.share.Mail.compose"):subject("[FCPX Hacks " .. fcpxhacks.scriptVersion .. "] Bug Report"):recipients({fcpxhacks.bugReportEmail})
																	   :shareItems({"Please enter any notes, comments or suggestions here.\n\n---",console.getConsole(true), screen.mainScreen():snapshot()})
	end

	--------------------------------------------------------------------------------
	-- PROWL API KEY VALID:
	--------------------------------------------------------------------------------
	function prowlAPIKeyValid(input)

		local result = false
		local errorMessage = nil

		prowlAction = "https://api.prowlapp.com/publicapi/verify?apikey=" .. input
		httpResponse, httpBody, httpHeader = http.get(prowlAction, nil)

		if string.match(httpBody, "success") then
			result = true
		else
			local xml = slaxdom:dom(tostring(httpBody))
			errorMessage = xml['root']['el'][1]['kids'][1]['value']
		end

		return result, errorMessage

	end

	--------------------------------------------------------------------------------
	-- DELETE ALL HIGHLIGHTS:
	--------------------------------------------------------------------------------
	function deleteAllHighlights()
		--------------------------------------------------------------------------------
		-- Delete FCPX Browser Highlight:
		--------------------------------------------------------------------------------
		if mod.browserHighlight then
			mod.browserHighlight:delete()
			if mod.browserHighlightTimer then
				mod.browserHighlightTimer:stop()
			end
		end
	end

	--------------------------------------------------------------------------------
	-- CHECK FOR FCPX HACKS UPDATES:
	--------------------------------------------------------------------------------
	function checkForUpdates()

		local enableCheckForUpdates = settings.get("fcpxHacks.enableCheckForUpdates")
		if enableCheckForUpdates then
			debugMessage("Checking for updates.")
			latestScriptVersion = nil
			updateResponse, updateBody, updateHeader = http.get(fcpxhacks.checkUpdateURL, nil)
			if updateResponse == 200 then
				if updateBody:sub(1,8) == "LATEST: " then
					--------------------------------------------------------------------------------
					-- Update Script Version:
					--------------------------------------------------------------------------------
					latestScriptVersion = updateBody:sub(9)

					--------------------------------------------------------------------------------
					-- macOS Notification:
					--------------------------------------------------------------------------------
					if not mod.shownUpdateNotification then
						if latestScriptVersion > fcpxhacks.scriptVersion then
							updateNotification = notify.new(function() getScriptUpdate() end):setIdImage(image.imageFromPath(fcpxhacks.iconPath))
																:title("FCPX Hacks Update Available")
																:subTitle("Version " .. latestScriptVersion)
																:informativeText("Do you wish to install?")
																:hasActionButton(true)
																:actionButtonTitle("Install")
																:otherButtonTitle("Not Yet")
																:send()
							mod.shownUpdateNotification = true
						end
					end

					--------------------------------------------------------------------------------
					-- Refresh Menubar:
					--------------------------------------------------------------------------------
					refreshMenuBar()
				end
			end
		end

	end

--------------------------------------------------------------------------------
-- TOUCH BAR:
--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- SHOW TOUCH BAR:
	--------------------------------------------------------------------------------
	function showTouchbar()
		--------------------------------------------------------------------------------
		-- Check if we need to show the Touch Bar:
		--------------------------------------------------------------------------------
		if touchBarSupported then
			local displayTouchBar = settings.get("fcpxHacks.displayTouchBar") or false
			if displayTouchBar then mod.touchBarWindow:show() end
		end
	end

	--------------------------------------------------------------------------------
	-- HIDE TOUCH BAR:
	--------------------------------------------------------------------------------
	function hideTouchbar()
		--------------------------------------------------------------------------------
		-- Hide the Touch Bar:
		--------------------------------------------------------------------------------
		if touchBarSupported then mod.touchBarWindow:hide() end
	end

	--------------------------------------------------------------------------------
	-- SET TOUCH BAR LOCATION:
	--------------------------------------------------------------------------------
	function setTouchBarLocation()

		--------------------------------------------------------------------------------
		-- Get Settings:
		--------------------------------------------------------------------------------
		local displayTouchBarLocation = settings.get("fcpxHacks.displayTouchBarLocation") or "Mouse"

		--------------------------------------------------------------------------------
		-- Show Touch Bar at Top Centre of Timeline:
		--------------------------------------------------------------------------------
		local timeline = fcp:timeline()
		if displayTouchBarLocation == "TimelineTopCentre" and timeline:isShowing() then
			--------------------------------------------------------------------------------
			-- Position Touch Bar to Top Centre of Final Cut Pro Timeline:
			--------------------------------------------------------------------------------
			local viewFrame = timeline:contents():viewFrame()

			local topLeft = {x = viewFrame.x + viewFrame.w/2 - mod.touchBarWindow:getFrame().w/2, y = viewFrame.y + 20}
			mod.touchBarWindow:topLeft(topLeft)
		else
			--------------------------------------------------------------------------------
			-- Position Touch Bar to Mouse Pointer Location:
			--------------------------------------------------------------------------------
			mod.touchBarWindow:atMousePosition()

		end

		--------------------------------------------------------------------------------
		-- Save last Touch Bar Location to Settings:
		--------------------------------------------------------------------------------
		settings.set("fcpxHacks.lastTouchBarLocation", mod.touchBarWindow:topLeft())

	end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------





--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                             W A T C H E R S                                --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- AUTOMATICALLY DO THINGS WHEN FINAL CUT PRO IS ACTIVATED OR DEACTIVATED:
--------------------------------------------------------------------------------
function finalCutProWatcher(appName, eventType, appObject)
	if (appName == "Final Cut Pro") then
		if (eventType == application.watcher.activated) then
			finalCutProActive()
		elseif (eventType == application.watcher.deactivated) or (eventType == application.watcher.terminated) then
			finalCutProNotActive()
		end
	end
end

--------------------------------------------------------------------------------
-- AUTOMATICALLY DO THINGS WHEN FINAL CUT PRO WINDOWS ARE CHANGED:
--------------------------------------------------------------------------------
function finalCutProWindowWatcher()

	wasInFullscreenMode = false

	--------------------------------------------------------------------------------
	-- Final Cut Pro Fullscreen Playback Filter:
	--------------------------------------------------------------------------------
	fullscreenPlaybackWatcher = windowfilter.new(true)

	--------------------------------------------------------------------------------
	-- Final Cut Pro Fullscreen Playback Window Created:
	--------------------------------------------------------------------------------
	fullscreenPlaybackWatcher:subscribe(windowfilter.windowCreated,(function(window, applicationName)
		if applicationName == "Final Cut Pro" then
			if window:title() == "" then
				local fcpx = fcp:application()
				if fcpx ~= nil then
					local fcpxElements = ax.applicationElement(fcpx)
					if fcpxElements ~= nil then
						if fcpxElements[1] ~= nil then
							if fcpxElements[1][1] ~= nil then
								if fcpxElements[1][1]:attributeValue("AXIdentifier") == "_NS:523" then
									-------------------------------------------------------------------------------
									-- Hide HUD:
									--------------------------------------------------------------------------------
									if settings.get("fcpxHacks.enableHacksHUD") then
											hackshud:hide()
											wasInFullscreenMode = true
									end
								end
							end
						end
					end
				end
			end
		end
	end), true)

	--------------------------------------------------------------------------------
	-- Final Cut Pro Fullscreen Playback Window Destroyed:
	--------------------------------------------------------------------------------
	fullscreenPlaybackWatcher:subscribe(windowfilter.windowDestroyed,(function(window, applicationName)
		if applicationName == "Final Cut Pro" then
			if window:title() == "" then
				-------------------------------------------------------------------------------
				-- Show HUD:
				--------------------------------------------------------------------------------
				if wasInFullscreenMode then
					if settings.get("fcpxHacks.enableHacksHUD") then
							hackshud:show()
					end
				end
			end
		end
	end), true)

	-- Watch the command editor showing and hiding.
	fcp:commandEditor():watch({
		show = function(commandEditor)
			--------------------------------------------------------------------------------
			-- Disable Hotkeys:
			--------------------------------------------------------------------------------
			if hotkeys ~= nil then -- For the rare case when Command Editor is open on load.
				debugMessage("Disabling Hotkeys")
				hotkeys:exit()
			end
			--------------------------------------------------------------------------------

			--------------------------------------------------------------------------------
			-- Hide the Touch Bar:
			--------------------------------------------------------------------------------
			hideTouchbar()

			--------------------------------------------------------------------------------
			-- Hide the HUD:
			--------------------------------------------------------------------------------
			hackshud.hide()
		end,
		hide = function(commandEditor)
			--------------------------------------------------------------------------------
			-- Check if we need to show the Touch Bar:
			--------------------------------------------------------------------------------
			showTouchbar()
			--------------------------------------------------------------------------------

			--------------------------------------------------------------------------------
			-- Refresh Keyboard Shortcuts:
			--------------------------------------------------------------------------------
			timer.doAfter(0.0000000000001, function() bindKeyboardShortcuts() end)
			--------------------------------------------------------------------------------

			--------------------------------------------------------------------------------
			-- Show the HUD:
			--------------------------------------------------------------------------------
			if settings.get("fcpxHacks.enableHacksHUD") then
				hackshud.show()
			end
		end
	})

	--------------------------------------------------------------------------------
	-- Final Cut Pro Window Moved:
	--------------------------------------------------------------------------------
	finalCutProWindowFilter = windowfilter.new{"Final Cut Pro"}

	finalCutProWindowFilter:subscribe(windowfilter.windowMoved, function()
		debugMessage("Final Cut Pro Window Resized")
		if touchBarSupported then
			local displayTouchBar = settings.get("fcpxHacks.displayTouchBar") or false
			if displayTouchBar then setTouchBarLocation() end
		end
	end, true)

	--------------------------------------------------------------------------------
	-- Final Cut Pro Window Not On Screen:
	--------------------------------------------------------------------------------
	finalCutProWindowFilter:subscribe(windowfilter.windowNotOnScreen, function()
		if not fcp:isFrontmost() then
			finalCutProNotActive()
		end
	end, true)

	--------------------------------------------------------------------------------
	-- Final Cut Pro Window On Screen:
	--------------------------------------------------------------------------------
	finalCutProWindowFilter:subscribe(windowfilter.windowOnScreen, function()
		finalCutProActive()
	end, true)

end

	--------------------------------------------------------------------------------
	-- Final Cut Pro Active:
	--------------------------------------------------------------------------------
	function finalCutProActive()

		--------------------------------------------------------------------------------
		-- Only do once:
		--------------------------------------------------------------------------------
		if mod.isFinalCutProActive then return end
		mod.isFinalCutProActive = true

		--------------------------------------------------------------------------------
		-- Don't trigger until after FCPX Hacks has loaded:
		--------------------------------------------------------------------------------
		if not mod.hacksLoaded then
			timer.waitUntil(function() return mod.hacksLoaded end, function()
				if fcp:isFrontmost() then
					mod.isFinalCutProActive = false
					finalCutProActive()
				end
			end, 0.1)
			return
		end

		--------------------------------------------------------------------------------
		-- Enable Hotkeys:
		--------------------------------------------------------------------------------
		timer.doAfter(0.0000000000001, function()
			hotkeys:enter()
		end)

		--------------------------------------------------------------------------------
		-- Enable Hacks HUD:
		--------------------------------------------------------------------------------
		timer.doAfter(0.0000000000001, function()
			if settings.get("fcpxHacks.enableHacksHUD") then
				hackshud:show()
			end
		end)

		--------------------------------------------------------------------------------
		-- Check if we need to show the Touch Bar:
		--------------------------------------------------------------------------------
		timer.doAfter(0.0000000000001, function()
			showTouchbar()
		end)

		--------------------------------------------------------------------------------
		-- Full Screen Keyboard Watcher:
		--------------------------------------------------------------------------------
		timer.doAfter(0.0000000000001, function()
			if settings.get("fcpxHacks.enableShortcutsDuringFullscreenPlayback") == true then
				fullscreenKeyboardWatcherUp:start()
				fullscreenKeyboardWatcherDown:start()
			end
		end)

		--------------------------------------------------------------------------------
		-- Enable Scrolling Timeline Watcher:
		--------------------------------------------------------------------------------
		timer.doAfter(0.0000000000001, function()
			if settings.get("fcpxHacks.scrollingTimelineActive") == true then
				if mod.scrollingTimelineWatcherDown ~= nil then
					mod.scrollingTimelineWatcherDown:start()
				end
			end
		end)

		--------------------------------------------------------------------------------
		-- Enable Lock Timeline Playhead:
		--------------------------------------------------------------------------------
		timer.doAfter(0.0000000000001, function()
			local lockTimelinePlayhead = settings.get("fcpxHacks.lockTimelinePlayhead") or false
			if lockTimelinePlayhead then
				fcp:timeline():lockPlayhead()
			end
		end)

		--------------------------------------------------------------------------------
		-- Enable Voice Commands:
		--------------------------------------------------------------------------------
		timer.doAfter(0.0000000000001, function()
			if settings.get("fcpxHacks.enableVoiceCommands") then
				voicecommands.start()
			end
		end)

		--------------------------------------------------------------------------------
		-- Update Menubar:
		--------------------------------------------------------------------------------
		timer.doAfter(0.0000000000001, function()
			refreshMenuBar()
		end)

		--------------------------------------------------------------------------------
		-- Update Current Language:
		--------------------------------------------------------------------------------
		timer.doAfter(0.0000000000001, function()
			fcp:getCurrentLanguage(true)
		end)

	end

	--------------------------------------------------------------------------------
	-- Final Cut Pro Not Active:
	--------------------------------------------------------------------------------
	function finalCutProNotActive()

		--------------------------------------------------------------------------------
		-- Only do once:
		--------------------------------------------------------------------------------
		if not mod.isFinalCutProActive then return end
		mod.isFinalCutProActive = false

		--------------------------------------------------------------------------------
		-- Don't trigger until after FCPX Hacks has loaded:
		--------------------------------------------------------------------------------
		if not mod.hacksLoaded then return end

		--------------------------------------------------------------------------------
		-- Full Screen Keyboard Watcher:
		--------------------------------------------------------------------------------
		if settings.get("fcpxHacks.enableShortcutsDuringFullscreenPlayback") == true then
			fullscreenKeyboardWatcherUp:stop()
			fullscreenKeyboardWatcherDown:stop()
		end

		--------------------------------------------------------------------------------
		-- Disable Scrolling Timeline Watcher:
		--------------------------------------------------------------------------------
		if settings.get("fcpxHacks.scrollingTimelineActive") == true then
			if mod.scrollingTimelineWatcherDown ~= nil then
				mod.scrollingTimelineWatcherDown:stop()
			end
		end

		--------------------------------------------------------------------------------
		-- Disable Lock Timeline Playhead:
		--------------------------------------------------------------------------------
		local lockTimelinePlayhead = settings.get("fcpxHacks.lockTimelinePlayhead") or false
		if lockTimelinePlayhead then
			fcp:timeline():unlockPlayhead()
		end

		--------------------------------------------------------------------------------
		-- Check if we need to hide the Touch Bar:
		--------------------------------------------------------------------------------
		hideTouchbar()

		--------------------------------------------------------------------------------
		-- Disable Voice Commands:
		--------------------------------------------------------------------------------
		if settings.get("fcpxHacks.enableVoiceCommands") then
			voicecommands.stop()
		end

		--------------------------------------------------------------------------------
		-- Disable hotkeys:
		--------------------------------------------------------------------------------
		hotkeys:exit()

		--------------------------------------------------------------------------------
		-- Delete the Mouse Circle:
		--------------------------------------------------------------------------------
		deleteAllHighlights()

		-------------------------------------------------------------------------------
		-- If not focussed on Hammerspoon then hide HUD:
		--------------------------------------------------------------------------------
		if settings.get("fcpxHacks.enableHacksHUD") then
			if application.frontmostApplication():bundleID() ~= "org.hammerspoon.Hammerspoon" then
				hackshud:hide()
			end
		end

		--------------------------------------------------------------------------------
		-- Disable Menubar Items:
		--------------------------------------------------------------------------------
		timer.doAfter(0.0000000000001, function() refreshMenuBar() end)
	end

--------------------------------------------------------------------------------
-- AUTOMATICALLY DO THINGS WHEN FCPX PLIST IS UPDATED:
--------------------------------------------------------------------------------
function finalCutProSettingsWatcher(files)
    doReload = false
    for _,file in pairs(files) do
        if file:sub(-24) == "com.apple.FinalCut.plist" then
            doReload = true
        end
    end
    if doReload then

		--------------------------------------------------------------------------------
		-- Refresh Keyboard Shortcuts if Command Set Changed & Command Editor Closed:
		--------------------------------------------------------------------------------
    	if mod.lastCommandSet ~= fcp:getActiveCommandSetPath() then
    		if not fcp:commandEditor():isShowing() then
	    		timer.doAfter(0.0000000000001, function() bindKeyboardShortcuts() end)
			end
		end

    	--------------------------------------------------------------------------------
    	-- Refresh Menubar:
    	--------------------------------------------------------------------------------
    	timer.doAfter(0.0000000000001, function() refreshMenuBar(true) end)

    	--------------------------------------------------------------------------------
    	-- Update Menubar Icon:
    	--------------------------------------------------------------------------------
    	timer.doAfter(0.0000000000001, function() updateMenubarIcon() end)

 		--------------------------------------------------------------------------------
		-- Reload Hacks HUD:
		--------------------------------------------------------------------------------
		if settings.get("fcpxHacks.enableHacksHUD") then
			timer.doAfter(0.0000000000001, function() hackshud:refresh() end)
		end

    end
end

--------------------------------------------------------------------------------
-- ENABLE SHORTCUTS DURING FCPX FULLSCREEN PLAYBACK:
--------------------------------------------------------------------------------
function fullscreenKeyboardWatcher()
	fullscreenKeyboardWatcherWorking = false
	fullscreenKeyboardWatcherUp = eventtap.new({ eventtap.event.types.keyUp }, function(event)
		fullscreenKeyboardWatcherWorking = false
	end)
	fullscreenKeyboardWatcherDown = eventtap.new({ eventtap.event.types.keyDown }, function(event)

		--------------------------------------------------------------------------------
		-- Don't repeat if key is held down:
		--------------------------------------------------------------------------------
		if fullscreenKeyboardWatcherWorking then return false end
		fullscreenKeyboardWatcherWorking = true

		--------------------------------------------------------------------------------
		-- Define Final Cut Pro:
		--------------------------------------------------------------------------------
		local fcpx = fcp:application()
		local fcpxElements = ax.applicationElement(fcpx)

		--------------------------------------------------------------------------------
		-- Only Continue if in Full Screen Playback Mode:
		--------------------------------------------------------------------------------
		if fcpxElements[1][1] ~= nil then
			if fcpxElements[1][1]:attributeValue("AXIdentifier") == "_NS:523" then

				--------------------------------------------------------------------------------
				-- Debug:
				--------------------------------------------------------------------------------
				debugMessage("Key Pressed whilst in Full Screen Mode.")

				--------------------------------------------------------------------------------
				-- Get keypress information:
				--------------------------------------------------------------------------------
				local whichKey = event:getKeyCode()			-- EXAMPLE: kc.keyCodeTranslator(whichKey) == "c"
				local whichModifier = event:getFlags()		-- EXAMPLE: whichFlags['cmd']

				--------------------------------------------------------------------------------
				-- Check all of these shortcut keys for presses:
				--------------------------------------------------------------------------------
				local fullscreenKeys = {"SetSelectionStart", "SetSelectionEnd", "AnchorWithSelectedMedia", "AnchorWithSelectedMediaAudioBacktimed", "InsertMedia", "AppendWithSelectedMedia" }

				for x, whichShortcutKey in pairs(fullscreenKeys) do
					if mod.finalCutProShortcutKey[whichShortcutKey] ~= nil then
						if mod.finalCutProShortcutKey[whichShortcutKey]['characterString'] ~= nil then
							if mod.finalCutProShortcutKey[whichShortcutKey]['characterString'] ~= "" then
								if whichKey == mod.finalCutProShortcutKey[whichShortcutKey]['characterString'] and tools.modifierMatch(whichModifier, mod.finalCutProShortcutKey[whichShortcutKey]['modifiers']) then
									eventtap.keyStroke({""}, "escape")
									eventtap.keyStroke(mod.finalCutProShortcutKey["ToggleEventLibraryBrowser"]['modifiers'], keycodes.map[mod.finalCutProShortcutKey["ToggleEventLibraryBrowser"]['characterString']])
									eventtap.keyStroke(mod.finalCutProShortcutKey[whichShortcutKey]['modifiers'], keycodes.map[mod.finalCutProShortcutKey[whichShortcutKey]['characterString']])
									eventtap.keyStroke(mod.finalCutProShortcutKey["PlayFullscreen"]['modifiers'], keycodes.map[mod.finalCutProShortcutKey["PlayFullscreen"]['characterString']])
									return true
								end
							end
						end
					end
				end
			end
			--------------------------------------------------------------------------------

			--------------------------------------------------------------------------------
			-- Fullscreen with playback controls:
			--------------------------------------------------------------------------------
			if fcpxElements[1][1][1] ~= nil then
				if fcpxElements[1][1][1][1] ~= nil then
					if fcpxElements[1][1][1][1]:attributeValue("AXIdentifier") == "_NS:51" then

						--------------------------------------------------------------------------------
						-- Get keypress information:
						--------------------------------------------------------------------------------
						local whichKey = event:getKeyCode()			-- EXAMPLE: kc.keyCodeTranslator(whichKey) == "c"
						local whichModifier = event:getFlags()		-- EXAMPLE: whichFlags['cmd']

						--------------------------------------------------------------------------------
						-- Check all of these shortcut keys for presses:
						--------------------------------------------------------------------------------
						local fullscreenKeys = {"SetSelectionStart", "SetSelectionEnd", "AnchorWithSelectedMedia", "AnchorWithSelectedMediaAudioBacktimed", "InsertMedia", "AppendWithSelectedMedia" }
						for x, whichShortcutKey in pairs(fullscreenKeys) do
							if mod.finalCutProShortcutKey[whichShortcutKey] ~= nil then
								if mod.finalCutProShortcutKey[whichShortcutKey]['characterString'] ~= nil then
									if mod.finalCutProShortcutKey[whichShortcutKey]['characterString'] ~= "" then
										if whichKey == mod.finalCutProShortcutKey[whichShortcutKey]['characterString'] and tools.modifierMatch(whichModifier, mod.finalCutProShortcutKey[whichShortcutKey]['modifiers']) then
											eventtap.keyStroke({""}, "escape")
											eventtap.keyStroke(mod.finalCutProShortcutKey["ToggleEventLibraryBrowser"]['modifiers'], keycodes.map[mod.finalCutProShortcutKey["ToggleEventLibraryBrowser"]['characterString']])
											eventtap.keyStroke(mod.finalCutProShortcutKey[whichShortcutKey]['modifiers'], keycodes.map[mod.finalCutProShortcutKey[whichShortcutKey]['characterString']])
											eventtap.keyStroke(mod.finalCutProShortcutKey["PlayFullscreen"]['modifiers'], keycodes.map[mod.finalCutProShortcutKey["PlayFullscreen"]['characterString']])
											return true
										end
									end
								end
							end
						end
					end
				end
			end
			--------------------------------------------------------------------------------

		end
	end)
end

--------------------------------------------------------------------------------
-- MEDIA IMPORT WINDOW WATCHER:
--------------------------------------------------------------------------------
function mediaImportWatcher()
	debugMessage("Watching for new media...")
	mod.newDeviceMounted = fs.volume.new(function(event, table)
		if event == fs.volume.didMount then

			debugMessage("Media Inserted.")

			local mediaImport = fcp:mediaImport()

			if mediaImport:isShowing() then
				-- Media Import was already open. Bail!
				debugMessage("Already in Media Import. Continuing...")
				return
			end

			local mediaImportCount = 0
			local stopMediaImportTimer = false
			local currentApplication = application.frontmostApplication()
			debugMessage("Currently using '"..currentApplication:name().."'")

			local fcpxHidden = not fcp:isShowing()

			mediaImportTimer = timer.doUntil(
				function()
					return stopMediaImportTimer
				end,
				function()
					if not fcp:isRunning() then
						debugMessage("FCPX is not running. Stop watching.")
						stopMediaImportTimer = true
					else
						if mediaImport:isShowing() then
							mediaImport:hide()
							if fcpxHidden then fcp:hide() end
							currentApplication:activate()
							debugMessage("Hid FCPX and returned to '"..currentApplication:name().."'.")
							stopMediaImportTimer = true
						end
						mediaImportCount = mediaImportCount + 1
						if mediaImportCount == 500 then
							debugMessage("Gave up watching for the Media Import window after 5 seconds.")
							stopMediaImportTimer = true
						end
					end
				end,
				0.01
			)

		end
	end)
	mod.newDeviceMounted:start()
end

--------------------------------------------------------------------------------
-- SCROLLING TIMELINE WATCHER:
--------------------------------------------------------------------------------
function scrollingTimelineWatcher()

	local timeline = fcp:timeline()

	--------------------------------------------------------------------------------
	-- Key Press Down Watcher:
	--------------------------------------------------------------------------------
	mod.scrollingTimelineWatcherDown = eventtap.new({ eventtap.event.types.keyDown }, function(event)

		--------------------------------------------------------------------------------
		-- Don't do anything if we're already locked.
		--------------------------------------------------------------------------------
		if timeline:isLockedPlayhead() then
			return false
		elseif event:getKeyCode() == 49 and next(event:getFlags()) == nil then
			--------------------------------------------------------------------------------
			-- Spacebar Pressed:
			--------------------------------------------------------------------------------
			checkScrollingTimeline()
		end
	end)
end

	--------------------------------------------------------------------------------
	-- CHECK TO SEE IF WE SHOULD ACTUALLY TURN ON THE SCROLLING TIMELINE:
	--------------------------------------------------------------------------------
	function checkScrollingTimeline()

		--------------------------------------------------------------------------------
		-- Make sure the Command Editor and hacks console are closed:
		--------------------------------------------------------------------------------
		if fcp:commandEditor():isShowing() or hacksconsole.active then
			debugMessage("Spacebar pressed while other windows are visible.")
			return "Stop"
		end

		--------------------------------------------------------------------------------
		-- Don't activate scrollbar in fullscreen mode:
		--------------------------------------------------------------------------------
		if fcp:fullScreenWindow():isShowing() then
			debugMessage("Spacebar pressed in fullscreen mode whilst watching for scrolling timeline.")
			return "Stop"
		end

		local timeline = fcp:timeline()

		--------------------------------------------------------------------------------
		-- Get Timeline Scroll Area:
		--------------------------------------------------------------------------------
		if not timeline:isShowing() then
			writeToConsole("ERROR: Could not find Timeline Scroll Area.")
			return "Stop"
		end

		--------------------------------------------------------------------------------
		-- Check mouse is in timeline area:
		--------------------------------------------------------------------------------
		local mouseLocation = geometry.point(mouse.getAbsolutePosition())
		local viewFrame = geometry.rect(timeline:contents():viewFrame())
		if mouseLocation:inside(viewFrame) then

			--------------------------------------------------------------------------------
			-- Mouse is in the timeline area when spacebar pressed so LET'S DO IT!
			--------------------------------------------------------------------------------
			debugMessage("Mouse inside Timeline Area.")
			timeline:lockPlayhead(true)
		else
			debugMessage("Mouse outside of Timeline Area.")
		end
	end

--------------------------------------------------------------------------------
-- NOTIFICATION WATCHER:
--------------------------------------------------------------------------------
function notificationWatcher()

	--------------------------------------------------------------------------------
	-- USED FOR DEVELOPMENT:
	--------------------------------------------------------------------------------
	--foo = distributednotifications.new(function(name, object, userInfo) print(string.format("name: %s\nobject: %s\nuserInfo: %s\n", name, object, inspect(userInfo))) end)
	--foo:start()

	--------------------------------------------------------------------------------
	-- SHARE SUCCESSFUL NOTIFICATION WATCHER:
	--------------------------------------------------------------------------------
	-- NOTE: ProTranscoderDidCompleteNotification doesn't seem to trigger when exporting small clips.
	shareSuccessNotificationWatcher = distributednotifications.new(notificationWatcherAction, "uploadSuccess")
	shareSuccessNotificationWatcher:start()

	--------------------------------------------------------------------------------
	-- SHARE UNSUCCESSFUL NOTIFICATION WATCHER:
	--------------------------------------------------------------------------------
	shareFailedNotificationWatcher = distributednotifications.new(notificationWatcherAction, "ProTranscoderDidFailNotification")
	shareFailedNotificationWatcher:start()

end

	--------------------------------------------------------------------------------
	-- NOTIFICATION WATCHER ACTION:
	--------------------------------------------------------------------------------
	function notificationWatcherAction(name, object, userInfo)

		local prowlAPIKey = settings.get("fcpxHacks.prowlAPIKey") or nil
		if prowlAPIKey ~= nil then

			local prowlApplication = http.encodeForQuery("FINAL CUT PRO")
			local prowlEvent = http.encodeForQuery("")
			local prowlDescription = nil

			if name == "uploadSuccess" then prowlDescription = http.encodeForQuery("Share Successful") end
			if name == "ProTranscoderDidFailNotification" then prowlDescription = http.encodeForQuery("Share Failed") end

			local prowlAction = "https://api.prowlapp.com/publicapi/add?apikey=" .. prowlAPIKey .. "&application=" .. prowlApplication .. "&event=" .. prowlEvent .. "&description=" .. prowlDescription
			httpResponse, httpBody, httpHeader = http.get(prowlAction, nil)

			if not string.match(httpBody, "success") then
				local xml = slaxdom:dom(tostring(httpBody))
				local errorMessage = xml['root']['el'][1]['kids'][1]['value'] or nil
				if errorMessage ~= nil then writeToConsole("PROWL ERROR: " .. tools.trim(tostring(errorMessage))) end
			end
		end

	end

--------------------------------------------------------------------------------
-- SHARED CLIPBOARD WATCHER:
--------------------------------------------------------------------------------
function sharedClipboardFileWatcher(files)
    doReload = false
    for _,file in pairs(files) do
        if file:sub(-10) == ".fcpxhacks" then
            doReload = true
        end
    end
    if doReload then
		debugMessage("Refreshing Shared Clipboard.")
		refreshMenuBar(true)
    end
end

--------------------------------------------------------------------------------
-- SHARED XML FILE WATCHER:
--------------------------------------------------------------------------------
function sharedXMLFileWatcher(files)
	debugMessage("Refreshing Shared XML Folder.")

	for _,file in pairs(files) do
        if file:sub(-7) == ".fcpxml" then
			local testFile = io.open(file, "r")
			if testFile ~= nil then
				testFile:close()

				local editorName = string.reverse(string.sub(string.reverse(file), string.find(string.reverse(file), "/", 1) + 1, string.find(string.reverse(file), "/", string.find(string.reverse(file), "/", 1) + 1) - 1))

				if host.localizedName() ~= editorName then

					local xmlSharingPath = settings.get("fcpxHacks.xmlSharingPath")
					sharedXMLNotification = notify.new(function() fcp:importXML(file) end)
						:setIdImage(image.imageFromPath(fcpxhacks.iconPath))
						:title("New XML Recieved")
						:subTitle(file:sub(string.len(xmlSharingPath) + 1 + string.len(editorName) + 1, -8))
						:informativeText("FCPX Hacks has recieved a new XML file.")
						:hasActionButton(true)
						:actionButtonTitle("Import XML")
						:send()

				end
			end
        end
    end

	refreshMenuBar()
end

--------------------------------------------------------------------------------
-- TOUCH BAR WATCHER:
--------------------------------------------------------------------------------
function touchbarWatcher(obj, message)

	if message == "didEnter" then
        mod.mouseInsideTouchbar = true
    elseif message == "didExit" then
        mod.mouseInsideTouchbar = false

        --------------------------------------------------------------------------------
	    -- Just in case we got here before the eventtap returned the Touch Bar to normal:
	    --------------------------------------------------------------------------------
        mod.touchBarWindow:movable(false)
        mod.touchBarWindow:acceptsMouseEvents(true)
		settings.set("fcpxHacks.lastTouchBarLocation", mod.touchBarWindow:topLeft())

    end

end

--------------------------------------------------------------------------------
-- AUTOMATICALLY RELOAD HAMMERSPOON WHEN CONFIG FILES ARE UPDATED:
--------------------------------------------------------------------------------
function hammerspoonConfigWatcher(files)
    doReload = false
    for _,file in pairs(files) do
        if file:sub(-4) == ".lua" then
            doReload = true
        end
    end
    if doReload then
        hs.reload()
    end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------





--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                L E T ' S     D O     T H I S     T H I N G !               --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

loadScript()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------