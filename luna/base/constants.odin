package luna_base

import "core:fmt"

KB :: 1024
MB :: 1024 * 1024
GB :: 1024 * 1024 * 1024

VEC2_UP :: vec2{1.0, 0.0}
VEC2_DOWN :: vec2{-1.0, 0.0}
VEC2_LEFT :: vec2{0.0, -1.0}
VEC2_RIGHT :: vec2{0.0, 1.0}
VEC2_ONE :: vec2{1.0, 1.0}
VEC2_ZERO :: vec2{0.0, 0.0}

VEC3_FORWARD :: vec3{1.0, 0.0, 0.0}
VEC3_BACKWARD :: vec3{-1.0, 0.0, 0.0}
VEC3_RIGHT :: vec3{0.0, 1.0, 0.0}
VEC3_LEFT :: vec3{0.0, -1.0, 0.0}
VEC3_UP :: vec3{0.0, 0.0, 1.0}
VEC3_DOWN :: vec3{0.0, 0.0, -1.0}
VEC3_ONE :: vec3{1.0, 1.0, 1.0}
VEC3_ZERO :: vec3{0.0, 0.0, 0.0}

COLOR_TRANSPARENT :: vec4{0.0, 0.0, 0.0, 0.0}
COLOR_RED :: vec4{1.0, 0.0, 0.0, 1.0}
COLOR_GREEN :: vec4{0.0, 1.0, 0.0, 1.0}
COLOR_BLUE :: vec4{0.0, 0.0, 1.0, 1.0}
COLOR_WHITE :: vec4{1.0, 1.0, 1.0, 1.0}
COLOR_BLACK :: vec4{0.0, 0.0, 0.0, 1.0}
COLOR_GRAY :: vec4{0.5, 0.5, 0.5, 1.0}
COLOR_SILVER :: vec4{0.75, 0.75, 0.75, 1.0}
COLOR_MAROON :: vec4{0.5, 0.0, 0.0, 1.0}
COLOR_YELLOW :: vec4{1.0, 1.0, 0.0, 1.0}
COLOR_OLIVE :: vec4{0.5, 0.5, 0.0, 1.0}
COLOR_LIME :: vec4{0.0, 1.0, 0.0, 1.0}
COLOR_AQUA :: vec4{0.0, 1.0, 1.0, 1.0}
COLOR_TEAL :: vec4{0.0, 0.5, 0.5, 1.0}
COLOR_NAVY :: vec4{0.0, 0.0, 0.5, 1.0}
COLOR_FUCHSIA :: vec4{1.0, 0.0, 1.0, 1.0}
COLOR_PURPLE :: vec4{0.5, 0.0, 0.5, 1.0}
COLOR_ORANGE :: vec4{1.0, 0.65, 0.0, 1.0}
COLOR_GOLD :: vec4{1.0, 0.84, 0.0, 1.0}
COLOR_PINK :: vec4{1.0, 0.75, 0.8, 1.0}
COLOR_PEACH :: vec4{1.0, 0.85, 0.7, 1.0}
COLOR_MAGENTA :: vec4{1.0, 0.0, 1.0, 1.0}
COLOR_LAVENDER :: vec4{0.9, 0.9, 0.98, 1.0}
COLOR_PLUM :: vec4{0.87, 0.63, 0.87, 1.0}
COLOR_TAN :: vec4{0.82, 0.71, 0.55, 1.0}
COLOR_BEIGE :: vec4{0.96, 0.96, 0.86, 1.0}
COLOR_MINT :: vec4{0.24, 0.71, 0.54, 1.0}
COLOR_LIME_GREEN :: vec4{0.2, 0.8, 0.2, 1.0}
COLOR_OLIVE_DRAB :: vec4{0.42, 0.56, 0.14, 1.0}
COLOR_BROWN :: vec4{0.43, 0.26, 0.06, 1.0}
COLOR_CHOCOLATE :: vec4{0.82, 0.41, 0.12, 1.0}
COLOR_CORAL :: vec4{1.0, 0.5, 0.31, 1.0}
COLOR_SALMON :: vec4{0.98, 0.5, 0.45, 1.0}
COLOR_TOMATO :: vec4{1.0, 0.39, 0.28, 1.0}
COLOR_CRIMSON :: vec4{0.86, 0.08, 0.24, 1.0}
COLOR_TURQUOISE :: vec4{0.25, 0.88, 0.82, 1.0}
COLOR_INDIGO :: vec4{0.29, 0.0, 0.51, 1.0}
COLOR_VIOLET :: vec4{0.93, 0.51, 0.93, 1.0}
COLOR_SKY_BLUE :: vec4{0.53, 0.81, 0.92, 1.0}
COLOR_SOFT_GRAY :: vec4{0.85, 0.70, 0.75, 1.0}
COLOR_CORNFLOWER_BLUE :: vec4{0.392, 0.584, 0.929, 1.0}

log_info :: proc(args: ..any) {
	fmt.print("[INFO] ")
	fmt.println(..args)
}

log_warn :: proc(args: ..any) {
	fmt.print("[WARN] ")
	fmt.println(..args)
}

log_error :: proc(args: ..any) {
	fmt.print("[ERROR] ")
	fmt.println(..args)
}

DEFAULT_WINDOW_WIDTH :: 1280
DEFAULT_WINDOW_HEIGHT :: 720
