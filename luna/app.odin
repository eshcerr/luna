package luna

import "assets"
import "base"
import "core"
import "gfx"
import "sfx"

import "core:strings"

import gl "vendor:OpenGL"
import "vendor:glfw"


app_t :: struct {
	setup_cb:                                               proc(app: ^app_t),
	init_cb:                                                proc(app: ^app_t),
	event_cb:                                               proc(app: ^app_t),
	update_cb:                                              proc(app: ^app_t),
	draw_cb:                                                proc(
		app: ^app_t,
		interpolated_delta_time: f32,
	),
	deinit_cb:                                              proc(app: ^app_t),
	title:                                                  string,
	delta_time, fixed_delta_time, update_per_seconds, time: f32,
	game_data:                                              ^any,
}


app_run :: proc(
	app: ^app_t,
	render_pip: ^gfx.render_pipeline_t,
	asset_pip: ^assets.asset_pipeline_t,
) {
	gfx.pip = render_pip
	assets.pip = asset_pip

	app.fixed_delta_time = 1.0 / app.update_per_seconds

	app_setup(app)
	app_init(app)
	defer app_deinit(app)

	current_frame: f32 = 0
	last_frame: f32 = 0
	timer: f32 = 0.0
	app.time = 0

	// update loop
	for !glfw.WindowShouldClose(render_pip.window_handle.(glfw.WindowHandle)) {
		current_frame = f32(glfw.GetTime())
		app.delta_time = current_frame - last_frame
		last_frame = current_frame

		glfw.SwapBuffers(render_pip.window_handle.(glfw.WindowHandle))
		app.time += app.delta_time
		timer += app.delta_time
		// fixed update loop
		for timer >= app.fixed_delta_time {
			timer -= app.fixed_delta_time
			// reset inputs values
			core.inputs_update()
			glfw.PollEvents()
			core.inputs_update_mouse(render_pip.window_handle.(glfw.WindowHandle))

			app.update_cb(app)
		}

		interpolated_delta_time := timer / app.fixed_delta_time
		app.draw_cb(app, interpolated_delta_time)
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
