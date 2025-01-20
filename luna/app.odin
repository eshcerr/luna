package luna

import "core:fmt"
import "core:strings"

import gl "vendor:OpenGL"
import "vendor:glfw"

GL_MAJOR_VERSION :: 4
GL_MINOR_VERSION :: 6

app_t :: struct {
	setup_cb:  proc(app: ^app_t),
	init_cb:   proc(app: ^app_t),
	event_cb:  proc(app: ^app_t),
	update_cb: proc(app: ^app_t),
	draw_cb:   proc(app: ^app_t),
	deinit_cb: proc(app: ^app_t),
	title:     string,
	window:    window_t,
}

window_t :: struct {
	width:    i32,
	height:   i32,
	bg_color: [4]f32,
	handle:   glfw.WindowHandle,
}

delta_time: f64 = 0
@(private = "file")
current_frame: f64 = 0
@(private = "file")
last_frame: f64 = 0

app_run :: proc(app: ^app_t) {
	app_setup(app)
	app_init(app)
	defer app_deinit(app)

	for (!glfw.WindowShouldClose(app.window.handle)) {
		current_frame = glfw.GetTime()
		delta_time = current_frame - last_frame
		last_frame = current_frame
		fmt.println(60.0 / delta_time)

		glfw.SwapBuffers((app.window.handle))
		glfw.PollEvents()

		app.update_cb(app)

		gl.ClearColor(
			app.window.bg_color.r,
			app.window.bg_color.g,
			app.window.bg_color.b,
			app.window.bg_color.a,
		)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		app.draw_cb(app)
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

	app.setup_cb(app)
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

	//glfw.SetKeyCallback(app.window.handle)


	fmt.println("luna initialisation completed")
	app.init_cb(app)
}

@(private = "file")
app_deinit :: proc(app: ^app_t) {
	app.deinit_cb(app)
	glfw.Terminate()
}

@(private = "file")
framebuffer_size_cb :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	gl.Viewport(0, 0, width, height)
}
