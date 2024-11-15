_G.data:extend({
	{
		type = "bool-setting",
		name = "folk-shuttle-dot-to-go",
		setting_type = "runtime-per-user",
		default_value = true,
	},
	{
		type = "string-setting",
		name = "folk-shuttle-ignore-stations",
		setting_type = "runtime-per-user",
		default_value = "",
		allow_blank = true,
	},
	{
		type = "color-setting",
		name = "folk-shuttle-color",
		setting_type = "runtime-per-user",
		default_value = { r = 0.07, g = 0.92, b = 0, a = 0.5, },
	},
	{
		type = "bool-setting",
		name = "folk-shuttle-clear-filter-on-confirm",
		setting_type = "runtime-per-user",
		default_value = true,
	},
	{
		type = "bool-setting",
		name = "folk-shuttle-focus-filter-on-show",
		setting_type = "runtime-per-user",
		default_value = true,
	},
})
