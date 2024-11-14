require("style")

do
	local item_sounds = require("__base__.prototypes.item_sounds")

	local input = {
		type = "custom-input",
		name = "shuttle-lite-call-nearest",
		key_sequence = "CONTROL + J",
		consuming = "none",
	}

	local shortcut = {
		type = "shortcut",
		name = "shuttle-lite-call-nearest",
		icon = "__folk-shuttle__/graphics/folk-shuttle-call.png",
		small_icon = "__folk-shuttle__/graphics/folk-shuttle-call.png",
		order = "c[custom-actions]-s[call-shuttle]",
		action = "lua",
		icon_size = 128,
		small_icon_size = 128,
		style = "green",
		associated_control_input = "shuttle-lite-call-nearest",
		technology_to_unlock = "shuttle-lite",
		unavailable_until_unlocked = true,
	}

	local item = {
		type = "item-with-entity-data",
		name = "folk-shuttle",
		icon = "__folk-shuttle__/graphics/folk-shuttle-locomotive.png",
		subgroup = "train-transport",
		order = "c[rolling-stock]-a[shuttle]",
		inventory_move_sound = item_sounds.locomotive_inventory_move,
		pick_sound = item_sounds.locomotive_inventory_pickup,
		drop_sound = item_sounds.locomotive_inventory_move,
		place_result = "folk-shuttle",
		stack_size = 5,
	}

	local recipe = {
		type = "recipe",
		name = "folk-shuttle",
		energy_required = 5,
		enabled = false,
		ingredients =
		{
			{ type = "item", name = "engine-unit",        amount = 20, },
			{ type = "item", name = "electronic-circuit", amount = 15, },
			{ type = "item", name = "advanced-circuit",   amount = 2, },
			{ type = "item", name = "steel-plate",        amount = 30, },
		},
		results = { { type = "item", name = "folk-shuttle", amount = 1, }, },
	}

	local tech = {
		type = "technology",
		name = "shuttle-lite",
		icon = "__folk-shuttle__/graphics/tech.png",
		icon_size = 256,
		effects = {
			{
				type = "nothing",
				use_icon_overlay_constant = false,
				icon = "__folk-shuttle__/graphics/folk-call-shuttle.png",
				icon_size = 128,
				effect_description = { "shuttle-lite.button-tooltip", },
			},
			{
				type = "unlock-recipe",
				recipe = "folk-shuttle",
			},
		},
		prerequisites = { "automated-rail-transportation", "radar", "advanced-circuit", },
		unit =
		{
			count = 200,
			ingredients =
			{
				{ "automation-science-pack", 1, },
				{ "logistic-science-pack",   1, },
			},
			time = 30,
		},
	}

	local honk = {
		type = "sound",
		name = "folk-shuttle-honk",
		filename = "__folk-shuttle__/honk.ogg",
		category = "environment",
		audible_distance_modifier = 8,
		volume = 1,
	}

	data:extend({ tech, input, shortcut, honk, item, recipe, })
end
