package luna_gfx

import "../base"
import "vendor:glfw"

supported_backend_e :: enum {
	opengl,
	// vulkan
}

view_mode_e :: enum {
	two_d,
	//three_d
}

window_provider_e :: enum {
	//native,
	glfw,
	//sdl2,
	//raylib,
}

window_t :: union {
	glfw.WindowHandle,
}

render_pipeline_t :: struct {
	window_provider:        window_provider_e,
	backend:                supported_backend_e,
	view_mode:              view_mode_e,
	game_camera, ui_camera: camera_t,
	clear_color:            base.vec4,
	window_size:            base.ivec2,
	window_handle:          window_t,
}

pip: ^render_pipeline_t
