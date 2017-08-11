--local ev = require("lib-events")

-- To remove the modgui button after a mod has been removed, run
--/c for i,p in pairs(game.players) do if p.gui.left.mod_gui_flow and p.gui.left.mod_gui_flow.mod_gui_button_flow and
-- p.gui.left.mod_gui_flow.mod_gui_button_flow.shuttle_lite_button then p.gui.left.mod_gui_flow.mod_gui_button_flow.shuttle_lite_button.destroy() end end

require("mod-gui")
local modGui = _G.mod_gui
local NAME = "shuttle-lite"

local updateIfVisible
local updateStationInterface

local sClearFilters = "folk-shuttle-clear-filters"
local sDotToGo = "folk-shuttle-dot-to-go"
local sIgnoreStations = "folk-shuttle-ignore-stations"
local getSetting
do
	local map = {
		[sClearFilters] = true,
		[sDotToGo] = true,
		[sIgnoreStations] = true,
	}
	local ini = {}
	getSetting = function(p, setting)
		if not ini[p.index] then ini[p.index] = {} end
		if type(ini[p.index][setting]) == "nil" then ini[p.index][setting] = settings.get_player_settings(p)[setting].value end
		return ini[p.index][setting]
	end
	local function update(event)
		if not map[event.setting] then return end
		if not ini[event.player_index] then ini[event.player_index] = {} end
		local value = settings.get_player_settings(game.players[event.player_index])[event.setting].value
		ini[event.player_index][event.setting] = value
		updateIfVisible(game.players[event.player_index])
		--ev.trigger(event.setting, event.player_index, value)
	end
	script.on_event(defines.events.on_runtime_mod_setting_changed, update)
end

local waitConditions = {
	{
		type = "time",
		compare_type = "and",
		ticks = 180,
	}
}

-- Create this every game load from global.stationEntities

local function clearFilters(p, frame)
	if not getSetting(p, sClearFilters) then return end
	if frame.one and frame.one["shuttle-lite-filter"] then
		frame.one["shuttle-lite-filter"].text = ""
	end
	global.filter[p.index] = nil
end

local function forceClose(p)
	local flow = modGui.get_frame_flow(p)
	if not flow then return end
	local frame = flow.shuttle_lite_frame
	if not frame then return end
	frame.style.visible = false
	clearFilters(p, frame)

	-- Forcefully rebuild filtered station array in getStations when stations are built/renamed/etc
	global.lastFilter[p.index] = nil
end

local function isInTable(t, v) for i = 1, #t do if t[i] == v then return true end end end
local function forceUpdate()
	for _, sorted in pairs(global.sortedStations) do
		for i = #sorted, 1, -1 do table.remove(sorted, i) end
	end
	for id, entity in pairs(global.stationEntities) do
		if entity and entity.valid then
			if not global.sortedStations[entity.force.name] then global.sortedStations[entity.force.name] = {} end
			if not isInTable(global.sortedStations[entity.force.name], entity.backer_name) then
				table.insert(global.sortedStations[entity.force.name], entity.backer_name)
			end
		else
			global.stationEntities[id] = nil
		end
	end
	for _, s in pairs(global.sortedStations) do
		table.sort(s)
	end
	for _, force in pairs(game.forces) do
		for _, p in next, force.players do
			forceClose(p)
		end
	end
end

local getStations
do
	-- map, key: actual station name, value: lowercased name
	local lowerCaseNames = setmetatable({}, {
		__index = function(self, k)
			local v = k:lower()
			rawset(self, k, v)
			return v
		end,
	})

	getStations = function(p, index)
		local s = global.page[index] and ((global.page[index] - 1) * 10 + 1) or 1
		if s < 1 then s = 1 end
		if not global.sortedStations[p.force.name] then return end

		if not global.filter[index] then
			local patterns = getSetting(p, sIgnoreStations)
			if patterns and patterns:len() ~= 0 then
				if not global.lastFilter[index] or global.lastFilter[index] ~= patterns then
					global.tempResults[index] = {}
					for _, station in next, global.sortedStations[p.force.name] do
						local hide
						for filter in patterns:gmatch("[^%,]+") do if station:find(filter, 1, true) then hide = true; break end end
						if not hide then table.insert(global.tempResults[index], station) end
					end
					global.lastFilter[index] = patterns
					return unpack(global.tempResults[index])
				else
					if s > #global.tempResults[index] then
						global.page[index] = nil
						s = 1
					end
					return unpack(global.tempResults[index], s)
				end
			else
				if s > #global.sortedStations[p.force.name] then
					global.page[index] = nil
					s = 1
				end
				return unpack(global.sortedStations[p.force.name], s)
			end
		else
			if not global.lastFilter[index] or global.lastFilter[index] ~= global.filter[index] then
				global.tempResults[index] = {} -- rehash all results
				local lower = global.filter[index]:lower()
				for _, station in next, global.sortedStations[p.force.name] do
					local match = true
					for word in lower:gmatch("%S+") do
						if not lowerCaseNames[station]:find(word, 1, true) then match = false end
					end
					if match then table.insert(global.tempResults[index], station) end
				end
				global.lastFilter[index] = global.filter[index]
				return unpack(global.tempResults[index])
			else
				if s > #global.tempResults[index] then
					global.page[index] = nil
					s = 1
				end
				return unpack(global.tempResults[index], s)
			end
		end
	end
end

do
	local stationButtons = setmetatable({}, {
		__index = function(self, k)
			local r = {
				type = "button",
				style = "shuttle-lite-station-button",
				caption = k,
			}
			rawset(self, k, r)
			return r
		end
	})
	local function doUpdate(f, ...)
		for i = 1, 10 do
			local s = (select(i, ...))
			-- when we unpack() the stations over an index that doesnt exist,
			-- we get lots of empty varargs
			if type(s) == "string" then
				f.add(stationButtons[s])
			end
		end
	end

	updateStationInterface = function(frame, p)
		if not frame or not frame.two then return end
		frame.two.clear()
		doUpdate(frame.two, getStations(p, p.index))
	end

	updateIfVisible = function(p)
		local frame = modGui.get_frame_flow(p).shuttle_lite_frame
		if not frame then return end
		if frame.style.visible then
			updateStationInterface(frame, p)
		end
	end

	-- ev.register(sIgnoreStations, function(event)
	-- 	local pIndex = unpack(event)
	-- 	print(sIgnoreStations .. " event for " .. pIndex)
	-- 	updateIfVisible(game.players[pIndex])
	-- end)
end

do
	local function initializeStations()
		global.stationEntities = {}
		local stations = game.surfaces.nauvis.find_entities_filtered({type = "train-stop"})
		if stations and #stations ~= 0 then
			for _, station in next, stations do
				global.stationEntities[station.unit_number] = station
			end
		end
		forceUpdate()
	end

	local function initGlobals()
		-- If the player filters stations in any way, we use this table
		-- instead of .sortedStations
		if not global.tempResults then global.tempResults = {} end
		-- key: player index, value: page index shown in GUI, from 1-N
		if not global.page then global.page = {} end
		-- key: player index, value: filter as typed
		if not global.lastFilter then global.lastFilter = {} end
		if not global.filter then global.filter = {} end
		-- key: force name, value: indexed array of sorted station names
		if not global.sortedStations then global.sortedStations = {} end
		if not global.stationEntities then initializeStations() end
	end

	script.on_init(initGlobals)

	script.on_configuration_changed(function(data)
		if data.mod_changes["folk-shuttle"] then
			initGlobals()
			forceUpdate()
		end
	end)

	local function enableAll(force, tech)
		for _, effect in next, tech.effects do
			if effect.type == "unlock-recipe" then
				local rec = effect.recipe
				if force.recipes[rec] then
					if not force.recipes[rec].enabled then
						force.recipes[rec].enabled = true
					end
					force.recipes[rec].reload()
				elseif not force.recipes[rec] then
					tech.researched = false
				end
			end
		end
	end

	local function reset(event)
		if not event or (not event.all and event.addon ~= "shuttle") then return end
		initializeStations()
		-- Check the tech
		for _, force in pairs(game.forces) do
			for name, tech in pairs(force.technologies) do
				if tech.valid and name == "shuttle-lite" and tech.researched then
					enableAll(force, tech)
				end
			end
		end
	end
	require("lib-reset")(reset)

	local function renamed(event)
		if not event or not event.entity or event.entity.type ~= "train-stop" then return end
		forceUpdate()
	end
	-- on_entity_renamed does not trigger when entity settings are copy+pasted
	script.on_event(defines.events.on_entity_renamed, renamed)

	-- invoked /after/ a paste is done
	local function pasted(event)
		if not event or not event.destination or event.destination.type ~= "train-stop" then return end
		forceUpdate()
	end
	script.on_event(defines.events.on_entity_settings_pasted, pasted)

	local function built(event)
		if not event or not event.created_entity then return end
		local e = event.created_entity
		if e.type == "train-stop" then
			global.stationEntities[e.unit_number] = e
			forceUpdate()
		end
	end
	script.on_event({defines.events.on_built_entity, defines.events.on_robot_built_entity}, built)

	local function destroyed(event)
		if event and event.entity and event.entity.type == "train-stop" then
			global.stationEntities[event.entity.unit_number] = nil
			forceUpdate()
		end
	end
	script.on_event(defines.events.on_entity_died, destroyed)
	script.on_event(defines.events.on_preplayer_mined_item, destroyed)
	script.on_event(defines.events.on_robot_pre_mined, destroyed)
end

local function hasEquipment(carriage)
	if carriage.grid and carriage.grid.equipment then
		for _, eq in pairs(carriage.grid.equipment) do
			if eq.name == NAME then return true end
		end
	end
	return false
end

local inShuttle = {}
do
	-- Must be safe to call even if we left a different vehicle type.
	local function leftVehicle(p)
		inShuttle[p.index] = nil
		local frame = modGui.get_frame_flow(p).shuttle_lite_frame
		if not frame then return end
		frame.style.visible = false
	end

	script.on_event(defines.events.on_player_mined_entity, function(event)
		local e = event.entity
		if not e or not e.unit_number then return end
		local p = game.players[event.player_index]
		if not p or not inShuttle[event.player_index] or inShuttle[event.player_index] ~= e.unit_number then return end
		leftVehicle(p)
	end)

	script.on_event(defines.events.on_player_driving_changed_state, function(event)
		local p = game.players[event.player_index]
		if not p then return end
		if p.vehicle and p.vehicle.valid then
			if p.vehicle.type ~= "locomotive" or not p.vehicle.train then return end
			if p.vehicle.unit_number and hasEquipment(p.vehicle.train.front_stock) then
				inShuttle[event.player_index] = p.vehicle.unit_number
				-- Show UI
				local frame = modGui.get_frame_flow(p).shuttle_lite_frame
				if not frame then return end
				updateStationInterface(frame, p)
				frame.style.visible = true
			end
		else
			leftVehicle(p)
		end
	end)
end

local investigate = {}
do
	local ignore = {
		[defines.train_state.no_schedule] = true,
		[defines.train_state.manual_control_stop] = true,
		[defines.train_state.manual_control] = true,
	}
	local noPath = {"shuttle-lite.no-path"}

	local function trainState(event)
		if not event or not event.train or not event.train.front_stock then return end
		if investigate[event.train.front_stock.unit_number] then
			local t = event.train
			if (t.state == defines.train_state.no_path) or (t.state == defines.train_state.path_lost) then
				t.manual_mode = true
				t.front_stock.force.print(noPath)
				investigate[t.front_stock.unit_number] = nil
			elseif ignore[t.state] then
				investigate[t.front_stock.unit_number] = nil
			elseif t.state == defines.train_state.wait_station and #t.schedule.records == 1 then
				t.manual_mode = true
				investigate[t.front_stock.unit_number] = nil
			end
		end
	end

	script.on_event(defines.events.on_train_changed_state, trainState)
end

local callShuttle
do
	local available = {
		[defines.train_state.no_schedule] = true,
		[defines.train_state.manual_control] = true,
		[defines.train_state.wait_station] = true,
	}
	--local color = {r = 0.07, g = 0.92, b = 0, a = 0.5} for posterity
	callShuttle = function(p, bestStation)
		local bestTrain = nil
		local lowestDistance = nil

		if not inShuttle[p.index] then
			for _, train in next, p.force.get_trains(p.surface) do
				if available[train.state] and train.front_stock then
					local free = false
					for _, carriage in next, train.carriages do
						if carriage.passenger then
							free = false
							break
						elseif hasEquipment(carriage) then
							free = true
						end
					end
					if free then
						-- this train can be used, find out how far away it is
						local distance = (((p.position.x - train.front_stock.position.x) ^ 2) + ((p.position.y - train.front_stock.position.y) ^ 2)) ^ 0.5
						if not lowestDistance or distance < lowestDistance then
							lowestDistance = distance
							bestTrain = train
						end
					end
				end
			end
			if not bestTrain then
				p.print({"shuttle-lite.no-train-found"})
				return
			end
		else
			bestTrain = p.vehicle.train
		end

		if not bestStation then
			lowestDistance = nil
			if p.opened and p.opened.type and p.opened.type == "train-stop" then
				bestStation = p.opened.backer_name
			else
				local stations = p.surface.find_entities_filtered({type = "train-stop", force=p.force})
				if stations and #stations ~= 0 then
					for _, station in next, stations do
						local distance = (((p.position.x - station.position.x) ^ 2) + ((p.position.y - station.position.y) ^ 2)) ^ 0.5
						if not lowestDistance or distance < lowestDistance then
							lowestDistance = distance
							bestStation = station.backer_name
						end
					end
				end
			end
			if not bestStation then
				p.print({"shuttle-lite.no-station-found"})
				return
			end
		end

		-- Is the train already at the station perhaps?
		if bestTrain.state == defines.train_state.wait_station and bestTrain.schedule.records[1].station == bestStation then
			p.print({"shuttle-lite.already-at-station"})
		else
			p.print({"shuttle-lite.train-coming", bestStation})
			-- register for investigation before we set the schedule/automatic mode
			investigate[bestTrain.front_stock.unit_number] = true
			bestTrain.schedule = {
				current = 1,
				records = {
					{
						station = bestStation,
						wait_conditions = waitConditions,
					}
				}
			}
			bestTrain.manual_mode = false
		end
	end
end

do
	local function initGui(player)
		local buttons = modGui.get_button_flow(player)
		if not buttons.shuttle_lite_button then
			buttons.add({
				type = "sprite-button",
				name = "shuttle_lite_button",
				sprite = "item/shuttle-lite",
				style = modGui.button_style,
				tooltip = {"shuttle-lite.button-tooltip"}
			})
		end

		local frames = modGui.get_frame_flow(player)
		local frame = frames.shuttle_lite_frame

		if not frame then
			frame = frames.add({
				type = "frame",
				name = "shuttle_lite_frame",
				direction = "vertical",
				style = modGui.frame_style
			})
		end
		if not frame.one then
			frame.add({
				type = "flow",
				name = "one",
				direction = "horizontal"
			})
		end
		if not frame.one["shuttle-lite-previous"] then
			frame.one.add({
				type = "sprite-button",
				name = "shuttle-lite-previous",
				sprite = "recipe/shuttle-left",
				style = "shuttle-lite-page-button",
			})
		end
		if not frame.one["shuttle-lite-filter"] then
			frame.one.add({
				type = "textfield",
				name = "shuttle-lite-filter",
				style = "shuttle-lite-text",
				tooltip = {"shuttle-lite.filter-tooltip"}
			})
		end
		if not frame.one["shuttle-lite-next"] then
			frame.one.add({
				type = "sprite-button",
				name = "shuttle-lite-next",
				sprite = "recipe/shuttle-right",
				style = "shuttle-lite-page-button",
			})
		end

		if not frame.two then
			frame.add({
				type = "flow",
				name = "two",
				direction = "vertical",
			})
		end

		frame.one.style.resize_to_row_height = true
		frame.one.style.resize_row_to_width = true
		frame.two.style.resize_to_row_height = true
		frame.two.style.resize_row_to_width = true

		frame.style.visible = false
	end
	script.on_event(defines.events.on_player_created, function(event)
		if game.players[event.player_index].force.technologies[NAME].researched then
			initGui(game.players[event.player_index])
		end
	end)

	script.on_event(defines.events.on_research_finished, function(event)
		if not event or not event.research then return end
		if event.research.name == NAME then
			for _, player in pairs(event.research.force.players) do
				initGui(player)
			end
		end
	end)
end

do
	local handle = {}

	handle["shuttle-lite-station-button"] = function(p, elem)
		local frame = modGui.get_frame_flow(p).shuttle_lite_frame
		if not frame or not frame.one then return end
		clearFilters(p, frame)
		if inShuttle[p.index] then
			local train = p.vehicle.train
			investigate[train.front_stock.unit_number] = true
			train.schedule = {current = 1, records = {{
				station = elem.caption,
				wait_conditions = waitConditions,
			}}}
			train.manual_mode = false
		else
			callShuttle(p, elem.caption)
		end
	end

	handle["shuttle_lite_button"] = function(p, _, event)
		if not event then return end
		if not inShuttle[p.index] and type(event.control) == "boolean" and event.control == true then
			callShuttle(p)
		else
			local frame = modGui.get_frame_flow(p).shuttle_lite_frame
			if not frame then return end
			frame.style.visible = not frame.style.visible
			if frame.style.visible then
				updateStationInterface(frame, p)
			end
		end
	end

	handle["shuttle-lite-previous"] = function(p)
		if not global.page[p.index] then return end
		global.page[p.index] = global.page[p.index] - 1
		if global.page[p.index] < 1 then global.page[p.index] = nil end
		updateIfVisible(p)
	end
	handle["shuttle-lite-next"] = function(p)
		global.page[p.index] = global.page[p.index] and global.page[p.index] + 1 or 2
		updateIfVisible(p)
	end

	script.on_event(defines.events.on_gui_click, function(event)
		if not event or not event.element then return end
		if handle[event.element.name] then
			handle[event.element.name](game.players[event.player_index], event.element, event)
		elseif event.element.style and event.element.style.name == "shuttle-lite-station-button" then
			handle["shuttle-lite-station-button"](game.players[event.player_index], event.element)
		end
	end)

	local function trim(s)
		local from = s:match("^%s*()")
		return from > #s and "" or s:match(".*%S", from)
	end
	script.on_event(defines.events.on_gui_text_changed, function(event)
		local elem = event.element
		if elem.name == "shuttle-lite-filter" and elem.text and type(elem.text) == "string" then
			local p = game.players[event.player_index]
			local frame = modGui.get_frame_flow(p).shuttle_lite_frame
			local input = trim(elem.text)
			if input:len() == 0 then
				global.filter[event.player_index] = nil
			else
				if input:find("%.$") and getSetting(p, sDotToGo) then
					-- find the top button
					if not frame or not frame.two then return end
					if type(frame.two.children[1]) ~= "nil" then
						handle["shuttle-lite-station-button"](p, frame.two.children[1])
					end
				else
					global.filter[event.player_index] = input
				end
			end
			updateStationInterface(frame, p)
		end
	end)
end

do
	local function valid(e) return e and e.valid and e.type == "train-stop" end
	local function keyCombo(event)
		local p = game.players[event.player_index]
		local explicit
		if valid(p.selected) then explicit = p.selected.backer_name
		elseif valid(p.opened) then explicit = p.opened.backer_name
		end
		callShuttle(p, explicit)
	end

	script.on_event("shuttle-lite-call-nearest", keyCombo)
end
