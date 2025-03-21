do
	-- ZZZ this could be moved to data, because elevated-rails updates
	-- ZZZ the locomotive in the first stage, and we optdep on it
	local util = require("__core__/lualib/util")

	local shuttle = util.copy(data.raw.locomotive.locomotive)
	shuttle.name = "folk-shuttle"
	shuttle.icon = "__folk-shuttle__/graphics/folk-shuttle-locomotive.png"
	shuttle.minable.result = "folk-shuttle"
	shuttle.default_copy_color_from_train_stop = false
	shuttle.color = { r = 0.07, g = 0.92, b = 0, a = 0.5, }
	shuttle.allow_manual_color = false
	shuttle.allow_remote_driving = false
	shuttle.minimap_representation.filename = "__folk-shuttle__/graphics/shuttle-minimap.png"
	shuttle.selected_minimap_representation.filename = "__folk-shuttle__/graphics/shuttle-minimap-selected.png"
	shuttle.hidden_in_factoriopedia = true

	if mods["elevated-rails"] then
		local elevated = require("__elevated-rails__.prototypes.sloped-trains-updates")
		local meld = require("__core__.lualib.meld")
		meld(shuttle, elevated.locomotive)
	end

	_G.data:extend({ shuttle, })
end
