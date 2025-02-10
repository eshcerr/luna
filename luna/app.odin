package luna

import "base"
import "core"
import "gfx"

import "core:fmt"
import "core:strings"

import gl "vendor:OpenGL"
import "vendor:glfw"

app_t :: struct {
	setup_cb:  proc(app: ^app_t),
	init_cb:   proc(app: ^app_t),
	event_cb:  proc(app: ^app_t),
	update_cb: proc(app: ^app_t),
	draw_cb:   proc(app: ^app_t),
	deinit_cb: proc(app: ^app_t),
	title:     string,
	game_data: ^any,
}

delta_time: f32 = 0
@(private = "file")
current_frame: f32 = 0
@(private = "file")
last_frame: f32 = 0

app_run :: proc(app: ^app_t, pip: ^gfx.render_pipeline_t) {
	gfx.pip = pip

	app_setup(app)
	app_init(app)
	defer app_deinit(app)

	for !glfw.WindowShouldClose(pip.window_handle.(glfw.WindowHandle)) {
		current_frame = f32(glfw.GetTime())
		delta_time = current_frame - last_frame
		last_frame = current_frame
		//fmt.println(60.0 / delta_time)
		glfw.SwapBuffers(pip.window_handle.(glfw.WindowHandle))

		// reset inputs values
		core.inputs_update()
		glfw.PollEvents()
		core.inputs_update_mouse(pip.window_handle.(glfw.WindowHandle))

		app.update_cb(app)
		app.draw_cb(app)
	}
}

@(private = "file")
app_setup :: proc(app: ^app_t) {
	gfx.render_pipeline_setup()
	app.setup_cb(app)
}

@(private = "file")
app_init :: proc(app: ^app_t) {
	gfx.render_pipeline_init(app.title)

	// TODO : move to input init 
	glfw.SetKeyCallback(gfx.pip.window_handle.(glfw.WindowHandle), core.inputs_listen_to_glfw_keys)
	glfw.SetMouseButtonCallback(
		gfx.pip.window_handle.(glfw.WindowHandle),
		core.inputs_listen_to_glfw_mouse_buttons,
	)
	glfw.SetFramebufferSizeCallback(gfx.pip.window_handle.(glfw.WindowHandle), framebuffer_size_cb)

	app.init_cb(app)
}

@(private = "file")
app_deinit :: proc(app: ^app_t) {
	app.deinit_cb(app)
	gfx.render_pipeline_deinit()
}

@(private = "file")
framebuffer_size_cb :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	gl.Viewport(0, 0, width, height)
	gfx.pip.window_size = base.ivec2{width, height}
}
