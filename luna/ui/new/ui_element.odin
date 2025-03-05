package luna_ui_new

import "../../base"
import "../../core"
import "../../gfx"

ui_element_layout_e :: enum {
	VERTICAL,
	HORIZONTAL,
}

sizing_mode_e :: enum {
	FIT,
	FIXED,
	GROW,
	PERCENT,
}

sizing_t :: struct {
	mode:    sizing_mode_e,
	min_max: [2]f32,
	percent: f32,
	current: f32,
}

sizing_fixed :: proc(value: f32) -> sizing_t {
	return sizing_t{mode = .FIXED, min_max = {value, value}}
}

sizing_fit :: proc(values: [2]f32) -> sizing_t {
	return sizing_t{mode = .FIT, min_max = {value, value}}
}

sizing_grow :: proc(value: [2]f32) -> sizing_t {
	return sizing_t{mode = .GROW, min_max = {value, value}}
}

sizing_percent :: proc(percent: f32) -> sizing_t {
	return sizing_t{mode = .PERCENT, percent = value}
}

ui_element_t :: struct {
	sizing:                         [2]sizing_t,
	children:                       []ui_element_t,
	padding, margin, corner_radius: base.vec4,
	border, background_color:       base.vec4,
	position:                       base.vec2,
	layout:                         ui_element_layout_e,
	child_gap:                      f32,
}
