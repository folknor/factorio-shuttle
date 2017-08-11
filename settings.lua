_G.data:extend({
	{
		type = "bool-setting",
		name = "folk-shuttle-add-grids",
		setting_type = "startup",
		default_value = true,
	},
	{
		type = "bool-setting",
		name = "folk-shuttle-dot-to-go",
		setting_type = "runtime-per-user",
		default_value = true,
	},
	{
		type = "bool-setting",
		name = "folk-shuttle-clear-filters",
		setting_type = "runtime-per-user",
		default_value = true,
	},
	{
		type = "string-setting",
		name = "folk-shuttle-ignore-stations",
		setting_type = "runtime-per-user",
		default_value = "",
		allow_blank = true,
	}
})
