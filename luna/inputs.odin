package luna

import "vendor:glfw"

buttons :: enum (u32) {
	KEY_SPACE,
	KEY_APOSTROPHE,
	KEY_COMMA,
	KEY_MINUS,
	KEY_PERIOD,
	KEY_SLASH,
	KEY_SEMICOLON,
	KEY_EQUAL,
	KEY_LEFT_BRACKET,
	KEY_BACKSLASH,
	KEY_RIGHT_BRACKET,
	KEY_GRAVE_ACCENT,
	KEY_WORLD_1,
	KEY_WORLD_2,
}

buttons_lookup := map[buttons]int {
	{buttons.KEY_SPACE, glfw.KEY_SPACE},
	{buttons.KEY_APOSTROPHE, glfw.KEY_APOSTROPHE},
	{buttons.KEY_COMMA, glfw.KEY_COMMA},
	{buttons.KEY_MINUS, glfw.KEY_MINUS},
}

inputs_raw_window_cb()

//inputs_get_bool_value :: proc() -> u8 {}
