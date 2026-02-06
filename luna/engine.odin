package luna

import "assets"
import "base"
import "core"
import "core/ecs"
import "core:fmt"
import "editor"
import "gfx"
import "sfx"

import "core:strings"
import "base:runtime"

import gl "vendor:OpenGL"
import "vendor:glfw"

import imgui "../vendor/odin-imgui"
import imgui_glfw "../vendor/odin-imgui/imgui_impl_glfw"
import imgui_opengl "../vendor/odin-imgui/imgui_impl_opengl3"

LUNA_DEFAULT_UPDATE_PER_SECOND :: 60
DISABLE_DOCKING :: #config(DISABLE_DOCKING, false)

g_engine: ^engine_t

engine_t :: struct {
	// window name
	title:           string,

	// time manager
	time:            engine_time_t,

	// core
	input:           ^core.input_t,
	ecs:             ^ecs.ecs_t,
	asset_manager:   ^assets.asset_manager_t,

	// rendering system
	renderer:        ^gfx.renderer_t,
	renderer_config: gfx.renderer_config_t,

	// pipeline & callbacks
	pipeline:        engine_pipeline_t,

	// editor (only when LUNA_EDITOR is defined)
	editor:          ^editor.editor_t,

	// userdata
	data:            rawptr,
}

engine_time_t :: struct {
	update_per_second:       f32,
	time:                    f32,
	delta_time:              f32,
	fixed_delta_time:        f32,
	interpolated_delta_time: f32,
	current_frame:           f32,
	last_frame:              f32,
}

engine_pipeline_t :: struct {
	callbacks: engine_callbacks_t,
}

engine_callbacks_t :: struct {
	setup_cb:        proc(engine: ^engine_t),
	init_cb:         proc(engine: ^engine_t),
	deinit_cb:       proc(engine: ^engine_t),
	update_cb:       proc(engine: ^engine_t, delta_time: f32),
	fixed_update_cb: proc(engine: ^engine_t, fixed_delta_time: f32),
	build_editor_cb: proc(engine: ^engine_t, delta_time: f32),
	draw_cb:         proc(engine: ^engine_t, interpolated_delta_time: f32),
}

engine_run :: proc(engine: ^engine_t) {
	g_engine = engine

	if g_engine.time.update_per_second == 0 {
		g_engine.time.update_per_second = LUNA_DEFAULT_UPDATE_PER_SECOND
	}
	g_engine.time.fixed_delta_time = 1.0 / g_engine.time.update_per_second

	engine_setup(g_engine)
	engine_init(g_engine)
	defer engine_deinit(g_engine)
	
	fixed_update_timer: f32 = 0

	for !gfx.renderer_should_close(g_engine.renderer) {
		// get time and calculate deltas
		g_engine.time.current_frame = f32(glfw.GetTime())
		g_engine.time.delta_time = g_engine.time.current_frame - g_engine.time.last_frame
		g_engine.time.last_frame = g_engine.time.current_frame

		// calculate global time and fixed update timer
		g_engine.time.time += g_engine.time.delta_time
		fixed_update_timer += g_engine.time.delta_time

		// get window events
		glfw.PollEvents()

		gfx.renderer_begin_frame(g_engine.renderer)

		// collect window inputs in input system
		core.inputs_update()
		core.inputs_update_mouse(g_engine.renderer.window_handle.(glfw.WindowHandle))
		core.inputs_update_gamepad()

		// game update call
		g_engine.pipeline.callbacks.update_cb(g_engine, g_engine.time.delta_time)

		// game fixed update call
		// can call it multiple times if there was a freeze to still have coherent physics and all
		for fixed_update_timer >= g_engine.time.fixed_delta_time {
			fixed_update_timer -= g_engine.time.fixed_delta_time
			g_engine.pipeline.callbacks.fixed_update_cb(g_engine, g_engine.time.fixed_delta_time)
		}

		// draw editor
		when base.LUNA_EDITOR {
			// build editor callback
			editor.editor_layout(g_engine.editor)
			g_engine.pipeline.callbacks.build_editor_cb(g_engine, engine.time.delta_time)
		}

		// start game rendering
		// reset lights
		gfx.renderer_clear_light(g_engine.renderer)

		// get lights and register
		lights := ecs.ecs_query(g_engine.ecs, gfx.light2D_t)
		for light_entity in lights {
			light := ecs.ecs_get_component(g_engine.ecs, light_entity, gfx.light2D_t)
			// might want to check if the light can be visible or not to add it or not to the rendering
			gfx.renderer_add_light(g_engine.renderer, light^)
		}

		// calculate smooth interpolated delta time
		g_engine.time.interpolated_delta_time = fixed_update_timer / g_engine.time.fixed_delta_time

		draw_game :: proc(batch: ^gfx.sprite_batch2D_t) {

			entities := ecs.ecs_query(g_engine.ecs, gfx.sprite_renderer_t, base.transform2D_t)
			for entity in entities {
				sprite_renderer := ecs.ecs_get_component(
					g_engine.ecs,
					entity,
					gfx.sprite_renderer_t,
				)
				transform := ecs.ecs_get_component(g_engine.ecs, entity, base.transform2D_t)

				gfx.sprite_batch2D_draw(batch, sprite_renderer, transform)
			}

			g_engine.pipeline.callbacks.draw_cb(g_engine, g_engine.time.interpolated_delta_time)
		}

		gfx.renderer_draw_scene(g_engine.renderer, draw_game)
		gfx.renderer_end_frame(g_engine.renderer)

		sfx.audio_update_musics(sfx.audio)
	}
}

@(private = "file")
engine_setup :: proc(engine: ^engine_t) {
	renderer, ok := gfx.renderer_init(engine.renderer_config)
	assert(ok, "failed to init renderer")
	engine.renderer = renderer

	engine.pipeline.callbacks.setup_cb(engine)
}

@(private = "file")
engine_init :: proc(engine: ^engine_t) {
	sfx.audio = sfx.audio_init()
	core.inputs_fill_lookup_tables()

	// TODO : move to input init
	glfw.SetKeyCallback(
		engine.renderer.window_handle.(glfw.WindowHandle),
		core.inputs_listen_to_glfw_keys,
	)
	glfw.SetMouseButtonCallback(
		engine.renderer.window_handle.(glfw.WindowHandle),
		core.inputs_listen_to_glfw_mouse_buttons,
	)
	glfw.SetFramebufferSizeCallback(
		engine.renderer.window_handle.(glfw.WindowHandle),
		framebuffer_size_cb,
	)
	glfw.SetCursorPosCallback(
		engine.renderer.window_handle.(glfw.WindowHandle),
		core.inputs_listen_to_glfw_cursor_pos,
	)
	glfw.SetScrollCallback(
		engine.renderer.window_handle.(glfw.WindowHandle),
		core.inputs_listen_to_glfw_scroll,
	)
	glfw.SetCharCallback(
		engine.renderer.window_handle.(glfw.WindowHandle),
		core.inputs_listen_to_glfw_char,
	)

	engine.asset_manager = assets.asset_manager_init("assets/")
	engine.ecs = ecs.ecs_init()

	engine.editor = editor.editor_init()
	engine.editor.ctx.ecs = engine.ecs
	engine.editor.ctx.asset_manager = engine.asset_manager

	engine.pipeline.callbacks.init_cb(engine)
}

@(private = "file")
engine_deinit :: proc(engine: ^engine_t) {
	engine.pipeline.callbacks.deinit_cb(engine)

	assets.asset_manager_deinit(engine.asset_manager)
	editor.editor_deinit(engine.editor)
	ecs.ecs_deinit(engine.ecs)

	sfx.audio_deinit(sfx.audio)
	core.inputs_deinit()

	gfx.renderer_deinit(engine.renderer)
}

@(private = "file")
framebuffer_size_cb :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	context = runtime.default_context()
	gl.Viewport(0, 0, width, height)
	// find a way to send data back to engine
	gfx.renderer_resize(g_engine.renderer, {width, height})
}
