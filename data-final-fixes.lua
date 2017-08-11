
-- I should do this in data-updates, but there are so many other
-- small addons like "VehicleEquipment" (though it's not called that, it has a spelling
-- error in its name) and others that add grids to vehicles in data-final-fixes.
-- So yeah, I don't know. Who knows?!
do
	local data = _G.data
	if settings.startup["folk-shuttle-add-grids"].value == true then
		for _, loc in pairs(data.raw.locomotive) do
			if not loc.equipment_grid then
				loc.equipment_grid = "shuttle-lite"
			end
		end
	end

	local checked = {}
	local function ensureCategory(name)
		if checked[name] then return end
		checked[name] = true

		local grid = data.raw["equipment-grid"][name]
		if type(grid) ~= "table" then return end
		if type(grid.equipment_categories) ~= "table" then grid.equipment_categories = {} end
		local found = false
		for _, cat in next, grid.equipment_categories do
			if cat == "shuttle-lite" then
				found = true
				break
			end
		end
		if not found then
			table.insert(grid.equipment_categories, "shuttle-lite")
		end
	end

	for _, loc in pairs(data.raw.locomotive) do
		if loc.equipment_grid then
			ensureCategory(loc.equipment_grid)
		end
	end

	-- Increase FARL grid to 4x2 to fit both modules
	-- thanks nexela
	local farlGrid = data.raw["equipment-grid"]["farl-equipment-grid"]
	if farlGrid then
		farlGrid.width = 4
		farlGrid.height = 2
	end
end
