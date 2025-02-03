package luna_gfx

import "../base"

supported_backend_e :: enum {
	opengl,
	// vulkan
}

view_mode_e :: enum {
	two_d,
	//_3d
}

window_provider_e :: enum {
    //native,
    glfw,
    //sdl2,
    //raylib,
}

render_pipeline_t :: struct {
    window_provider: window_provider_e,
	backend:   supported_backend_e,
	view_mode: view_mode_e,
    clear_color: base.vec4
}
