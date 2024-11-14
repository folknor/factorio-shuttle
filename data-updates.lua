do
	-- I think we need this in -updates, because I think elevated-rails
	-- modifies the locomotive prototype in -updates? I've not double checked.

	local elevated = require("__elevated-rails__.prototypes.sloped-trains-updates")
	local meld = require("__core__.lualib.meld")

	local shuttle = table.deepcopy(data.raw.locomotive.locomotive)
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

	meld(shuttle, elevated.locomotive)

	_G.data:extend({ shuttle, })
end
