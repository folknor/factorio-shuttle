local modGui = require("mod-gui")
local VERSION = require("version")

-- TODO
-- Fix XXX comments
-- GUI arrows? Only when path not found etc?
-- Hack around multiple stations with the same name by sending the shuttle to the stations rail entity instead

local showGui, hideGui, updateGuiIfVisible, updateStationButtonVisibilities
local investigate = {}
local onConfChangedFuncs = {}

local ERROR_CONFIG = {
	color = { 1, 0, 0, 1, },
	sound_path = "utility/cannot_build",
}
local ERROR_NO_TRAIN = { "shuttle-lite.no-train-found", }
local ERROR_NO_STATION = { "shuttle-lite.no-station-found", }
local ERROR_NO_RAIL = { "shuttle-lite.no-rail-found", }
local ERROR_STATION_GONE = { "shuttle-lite.station-gone", }
local ERROR_NO_PATH = { "shuttle-lite.no-path", }

local INFO_ALREADY_AT_STATION = "shuttle-lite.already-at-station"
local INFO_SHUTTLE_INCOMING = "shuttle-lite.train-coming"
local INFO_SHUTTLE_INCOMING_RAIL = { "shuttle-lite.train-coming-rail", }

local FILTER_LEADING_SPACE = "^%s*()"
local FILTER_TRAILING_SPACE = ".*%S"
local FILTER_NON_SPACE = "%S+"
local FILTER_CSV = "[^%,]+"
local FILTER_TRAILING_DOT = "%.$"
local EMPTY_STRING = ""
local ELEMENT_TEXTBOX_FILTER = "shuttle_lite_filter"

local C_SEARCH_DIRECTION = "respect-movement-direction"
local C_LUA_EVENT = "shuttle-lite-call-nearest"

-- vehicle.type = locomotive
-- vehicle.train.front_stock.type = locomotive
-- vehicle.name = folk-shuttle
-- vehicle.train.front_stock.name = folk-shuttle
local C_ENT_TYPE_LOCOMOTIVE = "locomotive"
local C_ENT_NAME_SHUTTLE = "folk-shuttle"

local C_TYPE_BUTTON = "button"
local C_STYLE_BUTTON = "shuttle-lite-station-button"

local SOUND_HONK = { path = "folk-shuttle-honk", }

--------------------------------------------------------------------------------------------------
-- SETTINGS
--

local sDotToGo = "folk-shuttle-dot-to-go"
local sIgnoreStations = "folk-shuttle-ignore-stations"
local sColor = "folk-shuttle-color"
local getSetting
do
	local map = {
		[sDotToGo] = true,
		[sIgnoreStations] = true,
		[sColor] = { r = 0.07, g = 0.92, b = 0, a = 0.5, },
	}
	local ini = {}
	getSetting = function(p, setting)
		if not ini[p.index] then ini[p.index] = {} end
		if type(ini[p.index][setting]) == "nil" then
			ini[p.index][setting] = settings.get_player_settings(p)[setting]
				.value
		end
		return ini[p.index][setting]
	end
	local function update(event)
		local p = game.players[event.player_index]
		if not p or not p.valid then return end
		if not map[event.setting] then return end
		if not ini[p.index] then ini[p.index] = {} end
		local value = settings.get_player_settings(p)[event.setting].value
		ini[p.index][event.setting] = value
		updateGuiIfVisible(p)
	end
	script.on_event(defines.events.on_runtime_mod_setting_changed, update)
end

--------------------------------------------------------------------------------------------------
-- UI
--

do
	local function initGui(player)
		local frame = player.gui.screen.add({
			type = "frame",
			caption = { "shuttle-lite.window-title", },
			name = "shuttle_lite_frame",
			direction = "vertical",
		})
		frame.auto_center = true
		frame.style.maximal_height = 400

		local inner = frame.add { name = "inner", type = "frame", direction = "vertical", style = "inside_shallow_frame", }
		inner.style.padding = 8

		inner.add({
			type = "textfield",
			name = "shuttle_lite_filter",
			style = "shuttle-lite-text",
			tooltip = { "shuttle-lite.filter-tooltip", },
		})

		local line = inner.add({
			type = "line",
			style = "inside_shallow_frame_with_padding_line",
		})
		line.style.bottom_margin = 8

		local scroll = inner.add { name = "list", type = "scroll-pane", style = "scroll_pane_in_shallow_frame", }
		scroll.style.margin = 4

		frame.visible = false

		return frame
	end

	local function resetGui(player)
		local ff = modGui.get_frame_flow(player)
		if ff and ff.shuttle_lite_frame then
			ff.shuttle_lite_frame.visible = false
			ff.shuttle_lite_frame.destroy()
		end

		local bf = modGui.get_button_flow(player)
		if bf and bf.shuttle_lite_button then
			bf.shuttle_lite_button.destroy()
		end

		local new = player.gui.screen.shuttle_lite_frame
		if new then
			new.visible = false
			new.destroy()
		end
	end

	table.insert(onConfChangedFuncs, function()
		for _, p in pairs(game.players) do
			if p.valid then resetGui(p) end
		end
	end)

	local function createStationButtons(f, stations)
		local map = {}
		for _, s in next, stations do
			if not map[s.backer_name] then
				map[s.backer_name] = { s.unit_number, }
			else
				table.insert(map[s.backer_name], s.unit_number)
			end
		end

		for name, un in pairs(map) do
			f.add({
				type = C_TYPE_BUTTON,
				style = C_STYLE_BUTTON,
				caption = name,
				tooltip = table.concat(un, "|"),
			})
		end
	end

	-- map, key: actual station name, value: lowercased name
	local lowerCaseNames = setmetatable({}, {
		__index = function(self, k)
			local v = k:lower()
			rawset(self, k, v)
			return v
		end,
	})

	local function trim(s)
		local from = s:match(FILTER_LEADING_SPACE)
		return from > #s and EMPTY_STRING or s:match(FILTER_TRAILING_SPACE, from)
	end

	function updateStationButtonVisibilities(p)
		local frame = p.gui.screen.shuttle_lite_frame
		if not frame then return end

		local btns = frame.inner.list.children

		for _, btn in next, btns do
			btn.visible = true
		end

		local lower = trim(frame.inner.shuttle_lite_filter.text:lower())

		if lower and lower:len() ~= 0 then
			for _, btn in next, btns do
				for word in lower:gmatch(FILTER_NON_SPACE) do
					if not lowerCaseNames[btn.caption]:find(word, 1, true) then
						btn.visible = false
						break
					end
				end
			end
		end
	end

	local function sortStations(a, b)
		return a.backer_name < b.backer_name
	end

	function showGui(player)
		local frame = player.gui.screen.shuttle_lite_frame
		if not frame then frame = initGui(player) end

		-- Create all the station buttons every time
		local stations = game.train_manager.get_train_stops({
			surface = player.surface,
			force = player.force,
			is_connected_to_rail = true,
		})
		table.sort(stations, sortStations)

		local patterns = getSetting(player, sIgnoreStations)
		if patterns and patterns:len() ~= 0 then
			for i = #stations, 1, -1 do
				local station = stations[i]
				for filter in patterns:gmatch(FILTER_CSV) do
					if station.backer_name:find(filter) then
						table.remove(stations, i)
						break
					end
				end
			end
		end

		frame.inner.list.clear()
		createStationButtons(frame.inner.list, stations)
		updateStationButtonVisibilities(player)
		frame.visible = true
		frame.inner.shuttle_lite_filter.focus()
	end

	-- Must always be safe to call regardless of any circumstance
	function hideGui(player)
		if not player or not player.valid then return end
		local frame = player.gui.screen.shuttle_lite_frame
		if not frame then return end
		frame.visible = false
	end

	function updateGuiIfVisible(player)
		local frame = player.gui.screen.shuttle_lite_frame
		if not frame then return end
		if frame.visible then showGui(player) end
	end
end

local function isShuttleValid(player, shuttle)
	if not shuttle or not shuttle.valid or not shuttle.front_stock or not shuttle.front_stock.valid then return false end

	if shuttle.front_stock.type ~= C_ENT_TYPE_LOCOMOTIVE or shuttle.front_stock.name ~= C_ENT_NAME_SHUTTLE then return false end

	-- ZZZ We don't care if:
	-- - The train is moving
	-- - The train contains the given player as a passenger
	-- - The train is in manual mode or not

	-- Check that the train can even move
	if shuttle.max_forward_speed <= 0 then return false end

	-- Check that the force is the same as the players force
	if shuttle.front_stock.force ~= player.force then return false end

	-- Check that the surface is the same as the players surface
	if shuttle.front_stock.surface ~= player.surface then return false end

	-- Check that it has no passengers, or the passenger is the given player
	if shuttle.passengers and #shuttle.passengers ~= 0 then
		for _, p in next, shuttle.passengers do
			if p and p.valid and p.index ~= player.index then return false end
		end
	end

	for p, s in pairs(storage.shuttle) do
		local lp = game.players[p]
		if not lp or not lp.valid or not s or not s.valid then
			-- Purge stale trains and/or players
			storage.shuttle[p] = nil
		else
			-- check that |train| isnt already assigned
			if s.id == shuttle.id and p ~= player.index then
				return false
			end
		end
	end

	return true
end

local function assignShuttle(player, shuttle)
	script.register_on_object_destroyed(shuttle)
	storage.shuttle[player.index] = shuttle
	investigate[shuttle.id] = true
end

local function freeShuttle(shuttleId)
	investigate[shuttleId] = nil
	for p, s in pairs(storage.shuttle) do
		if (s.valid and s.id == shuttleId) or not s.valid then
			storage.shuttle[p] = nil
			hideGui(game.players[p])
		end
	end
end

local function freePlayer(p)
	storage.shuttle[p.index] = nil
	hideGui(p)
end

local waitConditions = {
	{
		type = "time",
		compare_type = "and",
		ticks = 180,
	},
}

do
	local function initGlobals()
		if not storage.releaseDate then storage = {} end
		if not storage.releaseDate then storage.releaseDate = VERSION end

		-- key: player index, value: LuaTrain
		-- https://lua-api.factorio.com/latest/classes/LuaTrain.html#id
		if not storage.shuttle then storage.shuttle = {} end

		-- UI filter text box content is saved by the game
	end

	script.on_init(initGlobals)

	table.insert(onConfChangedFuncs, function(data)
		if data.mod_changes[C_ENT_NAME_SHUTTLE] then
			initGlobals()
		end
	end)
end

script.on_event(defines.events.on_player_mined_entity, function(event)
	local e = event.entity
	if not e or not e.valid or not e.unit_number or not e.train or not e.train.id then return end
	freeShuttle(e.train.id)
end)

script.on_event(defines.events.on_object_destroyed, function(event)
	if event.type == defines.target_type.train then
		freeShuttle(event.useful_id)
	end
end)

script.on_event(defines.events.on_player_driving_changed_state, function(event)
	local p = game.players[event.player_index]
	if not p then return end
	if p.vehicle and p.vehicle.valid and p.vehicle.name == C_ENT_NAME_SHUTTLE and p.vehicle.train and p.vehicle.train.id then
		if isShuttleValid(p, p.vehicle.train) then
			assignShuttle(p, p.vehicle.train)
			showGui(p)
		end
	else
		hideGui(p)
	end
end)

script.on_event(defines.events.on_train_changed_state, function(event)
	if not event or not event.train or not event.train.valid then return end

	if investigate[event.train.id] then
		local t = event.train
		if (t.state == defines.train_state.no_path) or (t.state == defines.train_state.path_lost) then
			for p, s in pairs(storage.shuttle) do
				if s and s.valid and s.id == t.id then
					local player = game.players[p]
					if player and player.valid and player.connected then
						player.print(ERROR_NO_PATH, ERROR_CONFIG)
					end
				end
			end
			-- Free the shuttle even if we're sitting in it
			freeShuttle(t.id)
		end
	end
end)

local function getShuttle(p)
	local shuttle

	if storage.shuttle[p.index] and storage.shuttle[p.index].valid and isShuttleValid(p, storage.shuttle[p.index]) then
		shuttle = storage.shuttle[p.index]
	elseif p.vehicle and p.vehicle.valid and p.vehicle.train and p.vehicle.train.valid and isShuttleValid(p, p.vehicle.train) then
		shuttle = p.vehicle.train
	else
		local lowestDistance
		local trains = game.train_manager.get_trains({
			surface = p.surface,
			force = p.force,
			stock = C_ENT_NAME_SHUTTLE,
		})

		for _, train in next, trains do
			if train.valid and train.max_forward_speed > 0 then
				local distance = (((p.position.x - train.front_stock.position.x) ^ 2) + ((p.position.y - train.front_stock.position.y) ^ 2)) ^
					0.5
				if not lowestDistance or distance < lowestDistance then
					if isShuttleValid(p, train) then
						lowestDistance = distance
						shuttle = train
					end
				end
			end
		end
	end

	if shuttle and shuttle.valid then
		assignShuttle(p, shuttle)
	else
		freePlayer(p)
	end

	return shuttle
end

local function isShuttleAtStation(shuttle, station)
	if shuttle.state == defines.train_state.wait_station and shuttle.schedule.records[1].station == station.backer_name then
		return true
	end
	if shuttle.station and shuttle.station.valid and shuttle.station.unit_number and shuttle.station.unit_number == station.unit_number then
		return true
	end
	return false
end

local function scheduleAndSendShuttle(p, shuttle, schedule)
	investigate[shuttle.id] = true
	shuttle.schedule = {
		current = 1,
		records = { schedule, },
	}
	shuttle.manual_mode = false
	p.play_sound(SOUND_HONK)
	for _, stock in next, shuttle.carriages do
		stock.color = getSetting(p, sColor)
	end
end

-- XXX move isvalidrail and also make an isvalidstation etc
local function sendShuttleToRail(p, shuttle, rail)
	if not rail or not rail.valid then
		p.print(ERROR_NO_RAIL, ERROR_CONFIG)
		return
	end
	if not shuttle or not shuttle.valid then
		p.print(ERROR_NO_TRAIN, ERROR_CONFIG)
		return
	end

	p.print(INFO_SHUTTLE_INCOMING_RAIL)
	scheduleAndSendShuttle(p, shuttle, {
		wait_conditions = waitConditions,
		rail = rail,
	})
end

local function sendShuttleToStation(p, shuttle, station)
	if not station or not station.valid then
		p.print(ERROR_NO_STATION, ERROR_CONFIG)
		return
	end
	if not shuttle or not shuttle.valid then
		p.print(ERROR_NO_TRAIN, ERROR_CONFIG)
		return
	end

	-- Is the train already at the station perhaps?
	if isShuttleAtStation(shuttle, station) then
		p.print({ INFO_ALREADY_AT_STATION, station.backer_name, })
	else
		p.print({ INFO_SHUTTLE_INCOMING, station.backer_name, })
		scheduleAndSendShuttle(p, shuttle, {
			station = station.backer_name,
			wait_conditions = waitConditions,
		})
	end
end

do
	local function buttonCallShuttle(p, button)
		local shuttle = getShuttle(p)

		if not shuttle or not shuttle.valid then
			p.print(ERROR_NO_TRAIN, ERROR_CONFIG)
			return
		end

		local stations = {}
		for w in button.tooltip:gmatch("([^|]+)") do
			table.insert(stations, w)
		end

		for i = #stations, 1, -1 do
			local ent = game.get_entity_by_unit_number(stations[i])
			if not ent or not ent.valid then
				table.remove(stations, i)
			end
		end

		if #stations == 0 then
			showGui(p) -- Recreates the UI
			p.print(ERROR_STATION_GONE, ERROR_CONFIG)
			return
		end

		local station = game.get_entity_by_unit_number(stations[math.random(#stations)])
		sendShuttleToStation(p, shuttle, station)
	end

	script.on_event(defines.events.on_gui_click, function(event)
		if not event or not event.element then return end
		if event.element.style and event.element.style.name == "shuttle-lite-station-button" then
			buttonCallShuttle(game.players[event.player_index], event.element)
		end
	end)

	script.on_event(defines.events.on_gui_text_changed, function(event)
		local el = event.element
		if el.name == ELEMENT_TEXTBOX_FILTER then
			local p = game.players[event.player_index]

			if event.element.text:find(FILTER_TRAILING_DOT) and getSetting(p, sDotToGo) then
				local btns = el.parent.list
				for _, btn in next, btns.children do
					if btn.visible then
						buttonCallShuttle(p, btn)
						break
					end
				end
				event.element.text = event.element.text:sub(1, -2)
			else
				updateStationButtonVisibilities(p)
			end
		end
	end)
end

do
	local function validStop(e) return e and e.valid and e.type == "train-stop" end

	-- pls if you know a better way hlep
	local function validRail(e)
		return e and e.valid and e.prototype and e.prototype.mineable_properties and
			e.prototype.mineable_properties.products and e.prototype.mineable_properties.products[1] and
			(e.prototype.mineable_properties.products[1].name == "rail" or e.prototype.mineable_properties.products[1].name == "rail-ramp")
	end

	local function distanceSort(a, b)
		return a[2] < b[2]
	end

	local function findNearestPathableStation(p, shuttle)
		local lowestDistance = nil
		local distances = {}
		local closest
		local tm = game.train_manager

		local stations = tm.get_train_stops({
			surface = p.surface,
			force = p.force,
			is_connected_to_rail = true,
		})
		for _, s in next, stations do
			local distance = (((p.position.x - s.position.x) ^ 2) + ((p.position.y - s.position.y) ^ 2)) ^ 0.5
			table.insert(distances, { s, distance, })
			if not lowestDistance or distance < lowestDistance then
				lowestDistance = distance
				closest = s
			end
		end

		if not closest then return end

		if not tm.request_train_path({
				train = shuttle,
				search_direction = C_SEARCH_DIRECTION,
				goals = { closest, },
			}).found_path then
			table.sort(distances, distanceSort)
			table.remove(distances, 1) -- We cant path here, so remove it

			for _, tuple in next, distances do
				local s = tuple[1]
				if tm.request_train_path({
						train = shuttle,
						search_direction = C_SEARCH_DIRECTION,
						goals = { s, },
					}).found_path then
					closest = s
					break
				end
			end
		end

		distances = nil
		return closest
	end

	local function keyCombo(event)
		local p = game.players[event.player_index]
		if not p or not p.valid then return end

		local shuttle = getShuttle(p)

		if not shuttle or not shuttle.valid then
			p.print(ERROR_NO_TRAIN, ERROR_CONFIG)
			return
		end

		if validRail(p.selected) then
			-- This is a rail woooo

			-- this doesn't work, it "randomly" returns true/false even with modified or no steps_limit or different directions
			-- local canpath = game.train_manager.request_train_path({
			-- 	train = shuttle,
			-- 	goals = {
			-- 		{
			-- 			rail = p.selected,
			-- 			direction = defines.rail_direction.front,
			-- 		},
			-- 	},
			-- 	steps_limit = 10000,
			-- 	search_direction = C_SEARCH_DIRECTION,
			-- })
			sendShuttleToRail(p, shuttle, p.selected)
		else
			local station

			if validStop(p.selected) then
				station = p.selected
			elseif validStop(p.opened) then
				station = p.opened
			end

			if not station then
				station = findNearestPathableStation(p, shuttle)
			end

			if not station then
				p.print(ERROR_NO_STATION, ERROR_CONFIG)
				return
			end

			if station and station.valid then
				if not game.train_manager.request_train_path({
						train = shuttle,
						search_direction = C_SEARCH_DIRECTION,
						goals = { station, },
					}).found_path then
					-- XXX should perhaps instruct findNearestPathableStation to ignore the current station
					station = findNearestPathableStation(p, shuttle)
				end
			end

			sendShuttleToStation(p, shuttle, station)
		end
	end

	script.on_event(C_LUA_EVENT, keyCombo)
	script.on_event("on_lua_shortcut", function(event)
		if not event or event.prototype_name ~= C_LUA_EVENT then return end
		keyCombo(event)
	end)
end

script.on_configuration_changed(function(data)
	for _, f in next, onConfChangedFuncs do
		f(data)
	end
end)
