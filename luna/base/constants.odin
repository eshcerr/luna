package luna_base

import "core:fmt"

color_white :: vec4{1, 1, 1, 1}
color_black :: vec4{0, 0, 0, 1}
color_red :: vec4{1, 0, 0, 1}
color_green :: vec4{0, 1, 0, 1}
color_blue :: vec4{0, 0, 1, 1}
color_yellow :: vec4{1, 1, 0, 1}
color_cyan :: vec4{0, 1, 1, 1}
color_magenta :: vec4{1, 0, 1, 1}

log_info :: fmt.println
log_warn :: fmt.println
log_err :: fmt.println

default_window_width :: 1280
default_window_height :: 720