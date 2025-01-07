package main

import "core:fmt"
import "core:strings"

import gl "vendor:OpenGL"
import "vendor:glfw"

GL_MAJOR_VERSION :: 4
GL_MINOR_VERSION :: 6

app_t :: struct {
	setup_cb:  proc(),
	init_cb:   proc(),
	event_cb:  proc(),
	update_cb: proc(),
	draw_cb:   proc(),
	deinit_cb: proc(),
	title:     string,
	window:    window_t,
}

window_t :: struct {
	width:            i32,
	height:           i32,
	bg_color: [4]f32,
	handle:           glfw.WindowHandle,
}

app_run :: proc(app: ^app_t) {
	_app = app;
	app_setup(app)
	app_init(app)
	defer app_deinit(app)

	for (!glfw.WindowShouldClose(app.window.handle)) {
		glfw.SwapBuffers((app.window.handle))
		glfw.PollEvents()

		app.update_cb()

		gl.ClearColor(
			app.window.bg_color.r,
			app.window.bg_color.g,
			app.window.bg_color.b,
			app.window.bg_color.a,
		)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		app.draw_cb()
	} 
}

@(private = "file")
app_setup :: proc(app: ^app_t) {
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_MAJOR_VERSION)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_MINOR_VERSION)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
	glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, true)
	glfw.WindowHint(glfw.CLIENT_API, glfw.OPENGL_API)
	glfw.WindowHint(glfw.DOUBLEBUFFER, true)

	if (glfw.Init() != true) {
		fmt.println("failed to init glfw")
		return
	}

	app.setup_cb()
}

@(private = "file")
app_init :: proc(app: ^app_t) {
	app.window.handle = glfw.CreateWindow(
		app.window.width,
		app.window.height,
		strings.clone_to_cstring(app.title),
		nil,
		nil,
	)

	if (app.window.handle == nil) {
		fmt.println("failed to create window")
		return
	}
	glfw.MakeContextCurrent(app.window.handle)
	glfw.SwapInterval(0)

	gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, glfw.gl_set_proc_address)
	gl.Viewport(0, 0, app.window.width, app.window.height)

	fmt.println("luna initialisation completed")
	app.init_cb()
}

@(private = "file")
app_deinit :: proc(app: ^app_t) {
	app.deinit_cb()
	glfw.Terminate()
}

@(private = "file")
framebuffer_size_cb :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	gl.Viewport(0, 0, width, height)
}
