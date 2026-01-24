package luna

import "core:fmt"
import "assets"
import "base"
import "core"
import "core/ecs"
import "editor"
import "gfx"
import "sfx"

import "core:strings"

import gl "vendor:OpenGL"
import "vendor:glfw"

import imgui "../vendor/odin-imgui"
import imgui_glfw "../vendor/odin-imgui/imgui_impl_glfw"
import imgui_opengl "../vendor/odin-imgui/imgui_impl_opengl3"

LUNA_DEFAULT_UPDATE_PER_SECOND :: 60
DISABLE_DOCKING :: #config(DISABLE_DOCKING, false)

application_t :: struct {
	title:         string,
	time:          application_time_t,
	pipeline:      ^application_pipeline_t,
	input:         ^core.input_t,
	ecs:           ^ecs.ecs_t,
	asset_manager: ^assets.asset_manager_t,
	editor:        ^editor.editor_t,
	data:          ^any,
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
	callbacks: ^application_callbacks_t,
	render:    ^gfx.render_pipeline_t,
}

application_callbacks_t :: struct {
	setup_cb:        proc(app: ^application_t),
	init_cb:         proc(app: ^application_t),
	deinit_cb:       proc(app: ^application_t),
	update_cb:       proc(app: ^application_t, delta_time: f32),
	fixed_update_cb: proc(app: ^application_t, fixed_delta_time: f32),
	build_editor_cb: proc(app: ^application_t, delta_time: f32),
	draw_cb:         proc(app: ^application_t, interpolated_delta_time: f32),
}

app_run :: proc(app: ^application_t) {
	if app.time.update_per_second == 0 {
		app.time.update_per_second = LUNA_DEFAULT_UPDATE_PER_SECOND
	}
	app.time.fixed_delta_time = 1.0 / app.time.update_per_second

	gfx.pip = app.pipeline.render

	app_setup(app)
	app_init(app)
	defer app_deinit(app)

	fixed_update_timer: f32 = 0

	for !glfw.WindowShouldClose(gfx.pip.window_handle.(glfw.WindowHandle)) {
		// get time and calculate deltas
		app.time.current_frame = f32(glfw.GetTime())
		app.time.delta_time = app.time.current_frame - app.time.last_frame
		app.time.last_frame = app.time.current_frame

		// calculate global time and fixed update timer
		app.time.time += app.time.delta_time
		fixed_update_timer += app.time.delta_time

		// get window events
		glfw.PollEvents()

		when base.LUNA_EDITOR {
			// start imgui new frame
			imgui_opengl.NewFrame()
			imgui_glfw.NewFrame()
			imgui.NewFrame()
		}

		// collect window inputs in input system
		core.inputs_update()
		core.inputs_update_mouse(gfx.pip.window_handle.(glfw.WindowHandle))
		core.inputs_update_gamepad()

		// game update call
		app.pipeline.callbacks.update_cb(app, app.time.delta_time)

		// game fixed update call
		// can call it multiple times if there was a freeze to still have coherent physics and all
		for fixed_update_timer >= app.time.fixed_delta_time {
			fixed_update_timer -= app.time.fixed_delta_time
			app.pipeline.callbacks.fixed_update_cb(app, app.time.fixed_delta_time)
		}

		when base.LUNA_EDITOR {
			// build editor callback
			editor.editor_layout(app.editor)
			app.pipeline.callbacks.build_editor_cb(app, app.time.delta_time)
			imgui.Render()
		}

		// calculate smooth interpolated delta time
		app.time.interpolated_delta_time = fixed_update_timer / app.time.fixed_delta_time
		app.pipeline.callbacks.draw_cb(app, app.time.interpolated_delta_time)

		when base.LUNA_EDITOR {
			// draw imgui
			imgui_opengl.RenderDrawData(imgui.GetDrawData())

			when !DISABLE_DOCKING {
				backup_current_window := glfw.GetCurrentContext()
				imgui.UpdatePlatformWindows()
				imgui.RenderPlatformWindowsDefault()
				glfw.MakeContextCurrent(backup_current_window)
			}
		}

		glfw.SwapBuffers(gfx.pip.window_handle.(glfw.WindowHandle))

		sfx.audio_update_musics(sfx.audio)
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
	glfw.SetCursorPosCallback(
		gfx.pip.window_handle.(glfw.WindowHandle),
		core.inputs_listen_to_glfw_cursor_pos,
	)
	glfw.SetScrollCallback(
		gfx.pip.window_handle.(glfw.WindowHandle),
		core.inputs_listen_to_glfw_scroll,
	)
	glfw.SetCharCallback(
		gfx.pip.window_handle.(glfw.WindowHandle),
		core.inputs_listen_to_glfw_char,
	)

	app.asset_manager = assets.asset_manager_init("assets/")
	app.ecs = ecs.ecs_init()

	app.editor = editor.editor_init()
		app.editor.ctx.ecs = app.ecs
	app.editor.ctx.asset_manager = app.asset_manager

	app.pipeline.callbacks.init_cb(app)
}

@(private = "file")
app_deinit :: proc(app: ^application_t) {
	app.pipeline.callbacks.deinit_cb(app)

	assets.asset_manager_deinit(app.asset_manager)
	editor.editor_deinit(app.editor)
	ecs.ecs_deinit(app.ecs)

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
