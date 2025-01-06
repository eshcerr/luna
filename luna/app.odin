package main

import "core:fmt"
import "core:strings"

import gl "vendor:OpenGL"
import "vendor:glfw"

GL_MAJOR_VERSION :: 4
GL_MINOR_VERSION :: 6

app :: struct {
	setup_cb:  proc(),
	init_cb:   proc(),
	event_cb:  proc(),
	update_cb: proc(),
	draw_cb:   proc(),
	deinit_cb: proc(),
	title:     string,
	window:    window,
}

window :: struct {
	width:  i32,
	height: i32,
	handle: glfw.WindowHandle,
}

app_run :: proc(app: ^app) {

	app_setup(app)
	app_init(app)

	for (!glfw.WindowShouldClose(app.window.handle)) {
		glfw.PollEvents()

		app.update_cb()

		gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		app.draw_cb()

		glfw.SwapBuffers((app.window.handle))
	}

	app_deinit(app)
}

app_setup :: proc(app: ^app) {
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

app_init :: proc(app: ^app) {
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
	glfw.SwapInterval(1)

	gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, glfw.gl_set_proc_address)

	fmt.println("luna initialisation completed")
	app.init_cb()
}

app_deinit :: proc(app: ^app) {
	app.deinit_cb()
	glfw.Terminate()
}
