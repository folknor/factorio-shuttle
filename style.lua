local default = _G.data.raw["gui-style"].default

default["shuttle-lite-station-button"] = {
	type = "button_style",
	parent = "button",
	font = "default-small",
	width = 182,
	height = 25,
	top_padding = 2,
	bottom_padding = 0,
}

default["shuttle-lite-text"] = {
	type = "textbox_style",
	top_padding = 2,
	bottom_padding = 2,
	left_padding = 2,
	right_padding = 2,
	bottom_margin = 8,
	width = 202,
	height = 24,
	rich_text_setting = "disabled",
	font = "default-small",
}
