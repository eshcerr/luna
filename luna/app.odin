package luna

import "assets"
import "base"
import "core"
import "gfx"
import "sfx"

import "core:strings"

import gl "vendor:OpenGL"
import "vendor:glfw"

LUNA_DEFAULT_UPDATE_PER_SECOND :: 60

application_t :: struct {
	title:    string,
	time:     application_time_t,
	pipeline: ^application_pipeline_t,
	input:    ^core.input_t,
	data:     ^any,
}

application_time_t :: struct {
	update_per_second,
	time,
	delta_time,
	fixed_delta_time,
	interpolated_delta_time,
	current_frame,
	last_frame: f32,
}

application_pipeline_t :: struct {
	callbacks:  ^application_callbacks_t,
	asset:  ^assets.asset_pipeline_t,
	render: ^gfx.render_pipeline_t,
}

application_callbacks_t :: struct {
	setup_cb:        proc(app: ^application_t),
	init_cb:         proc(app: ^application_t),
	deinit_cb:       proc(app: ^application_t),
	update_cb:       proc(app: ^application_t, delta_time: f32),
	fixed_update_cb: proc(app: ^application_t, fixed_delta_time: f32),
	draw_cb:         proc(app: ^application_t, interpolated_delta_time: f32),
}

app_run :: proc(app: ^application_t) {
	if app.time.update_per_second == 0 {
		app.time.update_per_second = LUNA_DEFAULT_UPDATE_PER_SECOND
	}
	app.time.fixed_delta_time = 1.0 / app.time.update_per_second

	gfx.pip = app.pipeline.render
	assets.pip = app.pipeline.asset

	app_setup(app)
	app_init(app)
	defer app_deinit(app)

	fixed_update_timer: f32 = 0

	for !glfw.WindowShouldClose(gfx.pip.window_handle.(glfw.WindowHandle)) {
		app.time.current_frame = f32(glfw.GetTime())
		app.time.delta_time = app.time.current_frame - app.time.last_frame
		app.time.last_frame = app.time.current_frame

		app.time.time += app.time.delta_time
		fixed_update_timer += app.time.delta_time

		glfw.SwapBuffers(gfx.pip.window_handle.(glfw.WindowHandle))
		sfx.audio_update_musics(sfx.audio)
		app.pipeline.callbacks.update_cb(app, app.time.delta_time)

		for fixed_update_timer >= app.time.fixed_delta_time {
			fixed_update_timer -= app.time.fixed_delta_time

			core.inputs_update()
			glfw.PollEvents()
			core.inputs_update_mouse(gfx.pip.window_handle.(glfw.WindowHandle))
			core.inputs_update_gamepad()

			app.pipeline.callbacks.fixed_update_cb(app, app.time.fixed_delta_time)
		}

		app.time.interpolated_delta_time = fixed_update_timer / app.time.fixed_delta_time
		app.pipeline.callbacks.draw_cb(app, app.time.interpolated_delta_time)
	}
}

@(private = "file")
app_setup :: proc(app: ^application_t) {
	gfx.render_pipeline_setup()
	app.pipeline.callbacks.setup_cb(app)
}

@(private = "file")
app_init :: proc(app: ^application_t) {
	gfx.render_pipeline_init(app.title)
	sfx.audio = sfx.audio_init()
	core.inputs_fill_lookup_tables()

	// TODO : move to input init
	glfw.SetKeyCallback(gfx.pip.window_handle.(glfw.WindowHandle), core.inputs_listen_to_glfw_keys)
	glfw.SetMouseButtonCallback(
		gfx.pip.window_handle.(glfw.WindowHandle),
		core.inputs_listen_to_glfw_mouse_buttons,
	)
	glfw.SetFramebufferSizeCallback(gfx.pip.window_handle.(glfw.WindowHandle), framebuffer_size_cb)

	app.pipeline.callbacks.init_cb(app)
}

@(private = "file")
app_deinit :: proc(app: ^application_t) {
	app.pipeline.callbacks.deinit_cb(app)
	sfx.audio_deinit(sfx.audio)
	core.inputs_deinit()
	gfx.render_pipeline_deinit()
	free(app.pipeline)
}

@(private = "file")
framebuffer_size_cb :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	gl.Viewport(0, 0, width, height)
	gfx.pip.window_size = base.ivec2{width, height}
}
