package luna_gfx

import "../base"

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

render_pipeline_t :: struct {
	window_provider:        window_provider_e,
	backend:                supported_backend_e,
	view_mode:              view_mode_e,
	game_camera, ui_camera: camera_t,
	clear_color:            base.vec4,
}
