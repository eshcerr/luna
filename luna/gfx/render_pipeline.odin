package luna_gfx

import "../base"

import "core:strings"

import gl "vendor:OpenGL"
import "vendor:glfw"

GL_MAJOR_VERSION :: 4
GL_MINOR_VERSION :: 3

supported_backend_e :: enum {
	opengl,
	// TODO : support vulkan
}

view_mode_e :: enum {
	two_d,
}

window_provider_e :: enum {
	//TODO : native window provider impl for windows and linux,
	glfw,
	//TODO : sdl2 window provider impl,
	//TODO : raylib window provider impl,
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

render_pipeline_setup :: proc() {
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_MAJOR_VERSION)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_MINOR_VERSION)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
	glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, true)
	glfw.WindowHint(glfw.CLIENT_API, glfw.OPENGL_API)
	glfw.WindowHint(glfw.DOUBLEBUFFER, true)

	if glfw.Init() != true {
		base.log_err("failed to init glfw")
		return
	}
}

render_pipeline_init :: proc(window_title: string) {
	handle: window_t = glfw.CreateWindow(
		pip.window_size.x,
		pip.window_size.y,
		strings.clone_to_cstring(window_title),
		nil,
		nil,
	)
	pip.window_handle = handle

	if pip.window_handle == nil {
		base.log_err("failed to create window")
		return
	}

	glfw.MakeContextCurrent(pip.window_handle.(glfw.WindowHandle))
	glfw.SwapInterval(0)

	gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, glfw.gl_set_proc_address)
	gl.Viewport(0, 0, pip.window_size.x, pip.window_size.y)
}

render_pipeline_deinit :: proc() {
	glfw.Terminate()
}
