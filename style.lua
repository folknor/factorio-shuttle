local default = _G.data.raw["gui-style"].default

default["shuttle-lite-station-button"] = {
	type = "button_style",
	parent = "button",
	font = "default-small",
	minimal_width = 182,
	maximal_width = 0,
	horizontally_stretchable = "on",
	maximal_height = 25,
	height = 25,
	top_padding = 2,
	bottom_padding = 0,
}

default["shuttle-lite-text"] = {
	type = "textbox_style",
	maximal_height = 24,
	top_padding = 2,
	bottom_padding = 2,
	left_padding = 2,
	right_padding = 2,
	bottom_margin = 8,
	minimal_width = 120,
	maximal_width = 0,
	horizontally_stretchable = "on",
	rich_text_setting = "disabled",
	font = "default-small",
}
