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

render_pipeline_t :: struct {
	backend:   supported_backend_e,
	view_mode: view_mode_e,
    clear_color: base.vec4
}
