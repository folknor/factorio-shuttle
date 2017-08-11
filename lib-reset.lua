-- Version 1 by folk, zx64
-- To the extent possible under law, the authors have waived all copyright and related or neighboring rights to lib-reset.lua.
-- http://creativecommons.org/publicdomain/zero/1.0/
-- In laymans terms: "do whatever you want with this file and its content"
-- Credits: folk, zx64
--[[

USAGE DESCRIPTION

Somewhere in the control scope of your addon:

local function reset(event)
	if not event or (not event.all and event.addon ~= "myaddon") then return end
	reinitializeAllMyStuffFromScratchLikeItsANewGameOrWhatever()
	for _, force in pairs(game.forces) do
		for name, tech in pairs(force.technologies) do
			if tech.valid and name == "mytech" and tech.researched then
				enableTurtlesAllTheWayDown()
			end
		end
	end
end
require("lib-reset")(reset)

And then, ingame, players will be able to execute from the console:
To reset your addon specifically: /reset myaddon
To reset all addons registered with the library: /reset

--]]

local MAJOR, MINOR, register = "lib-reset", 1, true
local eventId
if remote.interfaces[MAJOR] then
	local newId = remote.call(MAJOR, "getEventId")
	if type(newId) ~= "nil" then eventId = newId
	else error("Previous version of lib-reset did not pass on the registered event ID.") end
	local version = remote.call(MAJOR, "version")
	if type(version) == "number" and version <= MINOR then register = false
	else
		local cmd = remote.call(MAJOR, "registeredCommand")
		if commands and type(cmd) == "string" then _G.commands.remove_command(cmd) end
		remote.remove_interface(MAJOR)
		print("More recent version of lib-reset has been detected.") --stdout print in case someone notices
	end
end
if register then
	local usedCommand
	local notification = "%s ran a /reset addons command."
	if type(eventId) ~= "number" then eventId = script.generate_event_name() end
	local function runReset(input)
		if type(input.parameter) == "string" then input.addon = input.parameter
		else input.all = true end
		script.raise_event(eventId, input)
		if game and game.print then
			if type(input) == "table" and input.player_index then game.print({"", notification:format(game.players[input.player_index].name)})
			else game.print({"", "Someone ran a /reset addons command."}) end
		end
	end
	remote.add_interface(MAJOR, {version=function() return MINOR end,registeredCommand=function() return usedCommand end, getEventId=function() return eventId end})
	if commands then
		for _, c in next, {"reset", "resetmod", "resetmods", "resetaddon", "resetaddons", "rstmds", "rstadd"} do
			if not commands.commands[c] and not commands.game_commands[c] then
				usedCommand = c
				commands.add_command(c, "", runReset)
				break
			end
		end
	end
end
return function(f) script.on_event(eventId, f) end
