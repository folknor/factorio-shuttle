local default = _G.data.raw["gui-style"].default

default["shuttle-lite-station-button"] = {
	type = "button_style",
	parent = "button",
	font = "default-small",
	minimal_width = 182,
	maximal_height = 25,
	height = 25,
	top_padding = 2,
	bottom_padding = 0,
}

default["shuttle-lite-page-button"] = {
	type = "button_style",
	parent = "button",
	font = "default-small",
	minimal_width = 25,
	maximal_width = 25,
	height = 25,
	top_padding = 2,
	bottom_padding = 2,
	left_padding = 2,
	right_padding = 2,
}

default["shuttle-lite-text"] = {
	type = "textfield_style",
	parent = "textfield",
	maximal_height = 24,
	top_padding = 2,
	bottom_padding = 2,
	left_padding = 2,
	right_padding = 2,
	minimal_width = 120,
	maximal_width = 120,
	font = "default-small",
}
