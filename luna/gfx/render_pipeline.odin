package luna_gfx

import "../base"
import "core:container/topological_sort"
import "core:fmt"
import "core:math/linalg"

import "core:strings"

import gl "vendor:OpenGL"
import "vendor:glfw"

import imgui "../../vendor/odin-imgui"
import imgui_glfw "../../vendor/odin-imgui/imgui_impl_glfw"
import imgui_opengl "../../vendor/odin-imgui/imgui_impl_opengl3"

GL_MAJOR_VERSION :: 4
GL_MINOR_VERSION :: 3
DISABLE_DOCKING :: #config(DISABLE_DOCKING, false)

supported_backend_e :: enum {
	OPENGL,
	// TODO : support vulkan
}

view_mode_e :: enum {
	TWO_D,
}

window_provider_e :: enum {
	//TODO : native window provider impl for windows and linux,
	GLFW,
	//TODO : sdl2 window provider impl,
	//TODO : raylib window provider impl,
}

window_t :: union {
	glfw.WindowHandle,
}

renderer_t :: struct {
	// window & context
	window_provider:       window_provider_e,
	backend:               supported_backend_e,
	window_handle:         window_t,
	window_size:           base.ivec2,
	window_title:          string,

	// views
	view_mode:             view_mode_e,
	game_camera:           camera_t,
	ui_camera:             camera_t,

	// sprite batching
	sprite_batch:          sprite_batch2D_t,

	// deferred lighting
	deferred_renderer:     deferred_light_renderer_t,
	use_deferred_renderer: bool,

	// default shaders
	default_shader:        ^shader_t,
	gbuffer_shader:        ^shader_t,
	light_shader:          ^shader_t,
	composite_shader:      ^shader_t,

	// projection matrix or camera
	projection:            base.mat4,

	// settings
	clear_color:           base.vec4,
	ambient_light:         f32,
	enable_editor:         bool,

	// debug
	stats:                 renderer_stats_t,
}

renderer_stats_t :: struct {
	draw_calls:   int,
	sprite_drawn: int,
	light_drawn:  int,
	frame_time:   f32,
	fps:          f32,
}

renderer_config_t :: struct {
	// window
	window_title:             string,
	window_width:             i32,
	window_height:            i32,
	window_provider:          window_provider_e,

	// graphics
	backend:                  supported_backend_e,
	view_mode:                view_mode_e,
	clear_color:              base.vec4,
	vsync:                    bool,

	// feature
	enable_deferred_lighting: bool,
	enable_editor:            bool,
}

renderer_config_default :: proc() -> renderer_config_t {
	return {
		window_title = "Luna game",
		window_width = 1280,
		window_height = 720,
		window_provider = .GLFW,
		backend = .OPENGL,
		view_mode = .TWO_D,
		clear_color = base.COLOR_CORNFLOWER_BLUE,
		vsync = true,
		enable_deferred_lighting = true,
		enable_editor = base.LUNA_EDITOR,
	}
}

renderer_init :: proc(config: renderer_config_t) -> (^renderer_t, bool) {
	renderer := new(renderer_t)

	renderer.window_provider = config.window_provider
	renderer.backend = config.backend
	renderer.view_mode = config.view_mode
	renderer.window_size = {config.window_width, config.window_height}
	renderer.window_title = config.window_title
	renderer.clear_color = config.clear_color
	renderer.use_deferred_renderer = config.enable_deferred_lighting

	renderer.game_camera = camera_t {
		position = {0, 0},
		zoom     = 1.0,
	}

	renderer.ui_camera = camera_t {
		position = {0, 0},
		zoom     = 1.0,
	}

	switch renderer.window_provider {
	case .GLFW:
		if !_renderer_init_glfw(renderer, config) {
			renderer_deinit(renderer)
			return nil, false
		}
	}

	switch renderer.backend {
	case .OPENGL:
		if !_renderer_init_opengl(renderer, config) {
			renderer_deinit(renderer)
			return nil, false
		}
	}

	when base.LUNA_EDITOR {
		if !_renderer_init_editor(renderer) {
			renderer_deinit(renderer)
			return nil, false
		}
	}

	renderer.default_shader = shader_init(
		"luna/gfx/shaders/sprite_batch.vert",
		"luna/gfx/shaders/sprite_batch.frag",
	)

	renderer.gbuffer_shader = shader_init(
		"luna/gfx/shaders/sprite_batch.vert",
		"luna/gfx/shaders/gbuffer.frag",
	)

	renderer.light_shader = shader_init(
		"luna/gfx/shaders/sprite_batch.vert",
		"luna/gfx/shaders/light.frag",
	)

	renderer.composite_shader = shader_init(
		"luna/gfx/shaders/fullscreen_quad.vert",
		"luna/gfx/shaders/composite.frag",
	)

	sprite_batch2D_init(&renderer.sprite_batch, renderer.default_shader)
	renderer.sprite_batch.default_viewport = renderer.window_size

	renderer.projection = linalg.matrix_ortho3d(
		0,
		f32(renderer.window_size.x),
		0,
		f32(renderer.window_size.y),
		-1000,
		1000,
	)

	gl.UseProgram(renderer.default_shader.program)
	shader_set_uniform(renderer.default_shader, "u_projection", &renderer.projection)

	if renderer.use_deferred_renderer {
		gl.UseProgram(renderer.gbuffer_shader.program)
		shader_set_uniform(renderer.gbuffer_shader, "u_projection", &renderer.projection)
		gl.UseProgram(renderer.light_shader.program)
		shader_set_uniform(renderer.light_shader, "u_projection", &renderer.projection)
		gl.UseProgram(renderer.composite_shader.program)
		shader_set_uniform(renderer.composite_shader, "u_projection", &renderer.projection)

		deferred_ok: bool
		renderer.deferred_renderer, deferred_ok = deferred_light_renderer_init(
			&renderer.sprite_batch,
			renderer.window_size,
		)
		if !deferred_ok {
			renderer_deinit(renderer)
			return nil, false
		}

		renderer.deferred_renderer.gbuffer_shader = renderer.gbuffer_shader
		renderer.deferred_renderer.light_shader = renderer.light_shader
		renderer.deferred_renderer.composite_shader = renderer.composite_shader
	}

	return renderer, true
}

@(private)
_renderer_init_glfw :: proc(renderer: ^renderer_t, config: renderer_config_t) -> bool {
	if !bool(glfw.Init()) {
		fmt.printf("failed to initialize GLFW")
		return false
	}

	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_MAJOR_VERSION)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_MINOR_VERSION)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
	glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, true)
	glfw.WindowHint(glfw.CLIENT_API, glfw.OPENGL_API)
	glfw.WindowHint(glfw.DOUBLEBUFFER, true)

	handle := glfw.CreateWindow(
		renderer.window_size.x,
		renderer.window_size.y,
		strings.clone_to_cstring(renderer.window_title, context.temp_allocator),
		nil,
		nil,
	)

	if handle == nil {
		fmt.eprintln("failed to create GLFW window")
		glfw.Terminate()
		return false
	}

	renderer.window_handle = handle

	glfw.MakeContextCurrent(handle)
	glfw.SwapInterval(config.vsync ? 1 : 0)

	return true
}

@(private)
_renderer_init_opengl :: proc(renderer: ^renderer_t, config: renderer_config_t) -> bool {
	gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, proc(p: rawptr, name: cstring) {
		(cast(^rawptr)p)^ = glfw.GetProcAddress(name)
	})

	gl.Viewport(0, 0, renderer.window_size.x, renderer.window_size.y)
	gl.Enable(gl.BLEND)
	gl.Enable(gl.FRAMEBUFFER_SRGB) // rgb gamma
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
	gl.Disable(gl.DEPTH_TEST)
	return true
}

@(private)
_renderer_init_editor :: proc(renderer: ^renderer_t) -> bool {
	when base.LUNA_EDITOR {
		imgui.CHECKVERSION()
		imgui.CreateContext()

		io := imgui.GetIO()
		io.ConfigFlags += {.NavEnableKeyboard, .NavEnableGamepad}

		when !DISABLE_DOCKING {
			io.ConfigFlags += {.DockingEnable}
			io.ConfigFlags += {.ViewportsEnable}

			style := imgui.GetStyle()
			style.WindowRounding = 0
			style.Colors[imgui.Col.WindowBg].w = 1
		}

		imgui_glfw.InitForOpenGL(renderer.window_handle.(glfw.WindowHandle), false)
		imgui_opengl.Init("#version 430")
		imgui.StyleColorsDark()

		return true
	} else {
		return false
	}
}

renderer_deinit :: proc(renderer: ^renderer_t) {
	if renderer == nil do return

	if renderer.use_deferred_renderer {
		deferred_light_renderer_deinit(&renderer.deferred_renderer)
	}

	sprite_batch2D_deinit(&renderer.sprite_batch)

	if renderer.default_shader != nil do free(renderer.default_shader)
	if renderer.gbuffer_shader != nil do free(renderer.gbuffer_shader)
	if renderer.light_shader != nil do free(renderer.light_shader)
	if renderer.composite_shader != nil do free(renderer.composite_shader)

	when base.LUNA_EDITOR {
		imgui_opengl.Shutdown()
		imgui_glfw.Shutdown()
		imgui.DestroyContext()
	}

	switch renderer.window_provider {
	case .GLFW:
		glfw.DestroyWindow(renderer.window_handle.(glfw.WindowHandle))
		glfw.Terminate()
	}

	free(renderer)
}

renderer_should_close :: proc(renderer: ^renderer_t) -> bool {
	switch renderer.window_provider {
	case .GLFW:
		return bool(glfw.WindowShouldClose(renderer.window_handle.(glfw.WindowHandle)))
	}
	return false
}

renderer_begin_frame :: proc(renderer: ^renderer_t) {
	gl.ClearColor(
		renderer.clear_color.r,
		renderer.clear_color.g,
		renderer.clear_color.b,
		renderer.clear_color.a,
	)
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

	// Start editor frame
	when base.LUNA_EDITOR {
		imgui_opengl.NewFrame()
		imgui_glfw.NewFrame()
		imgui.NewFrame()
	}

	renderer.stats.draw_calls = 0
	renderer.stats.sprite_drawn = 0
	renderer.stats.light_drawn = len(renderer.deferred_renderer.lights)
}

renderer_end_frame :: proc(renderer: ^renderer_t) {
	// End editor frame
	when base.LUNA_EDITOR {
		imgui.Render()
		imgui_opengl.RenderDrawData(imgui.GetDrawData())

		when !DISABLE_DOCKING {
			io := imgui.GetIO()
			if .ViewportsEnable in io.ConfigFlags {
				backup := glfw.GetCurrentContext()
				imgui.UpdatePlatformWindows()
				imgui.RenderPlatformWindowsDefault()
				glfw.MakeContextCurrent(backup)
			}
		}
	}

	renderer.stats.draw_calls = len(renderer.sprite_batch.draw_calls)
	renderer.stats.sprite_drawn = renderer.sprite_batch.instance_count

	// Swap buffers
	switch renderer.window_provider {
	case .GLFW:
		glfw.SwapBuffers(renderer.window_handle.(glfw.WindowHandle))
	}
}

renderer_draw_scene :: proc(renderer: ^renderer_t, draw_cb: proc(batch: ^sprite_batch2D_t)) {
	if renderer.use_deferred_renderer {
		deferred_light_renderer_render_scene(&renderer.deferred_renderer, draw_cb)
	} else {
		sprite_batch2D_begin(&renderer.sprite_batch)
		draw_cb(&renderer.sprite_batch)
		sprite_batch2D_end(&renderer.sprite_batch)
	}
}

renderer_draw_immediate :: proc(renderer: ^renderer_t, draw_cb: proc(batch: ^sprite_batch2D_t)) {
	sprite_batch2D_begin(&renderer.sprite_batch)
	draw_cb(&renderer.sprite_batch)
	sprite_batch2D_end(&renderer.sprite_batch)
}

renderer_add_light :: proc(renderer: ^renderer_t, light: light2D_t) {
	if renderer.use_deferred_renderer {
		deferred_light_renderer_add_light(&renderer.deferred_renderer, light)
	}
}

renderer_clear_light :: proc(renderer: ^renderer_t) {
	if renderer.use_deferred_renderer {
		deferred_light_renderer_clear_lights(&renderer.deferred_renderer)
	}
}

renderer_resize :: proc(renderer: ^renderer_t, dimensions: base.ivec2) {
	renderer.window_size = dimensions
	renderer.sprite_batch.default_viewport = renderer.window_size

	renderer.projection = linalg.matrix_ortho3d(
		0,
		f32(renderer.window_size.x),
		0,
		f32(renderer.window_size.y),
		-1000,
		1000,
	)

	gl.UseProgram(renderer.default_shader.program)
	shader_set_uniform(renderer.default_shader, "u_projection", &renderer.projection)

	if renderer.use_deferred_renderer {
		gl.UseProgram(renderer.gbuffer_shader.program)
		shader_set_uniform(renderer.gbuffer_shader, "u_projection", &renderer.projection)
		gl.UseProgram(renderer.light_shader.program)
		shader_set_uniform(renderer.light_shader, "u_projection", &renderer.projection)
		gl.UseProgram(renderer.composite_shader.program)
		shader_set_uniform(renderer.composite_shader, "u_projection", &renderer.projection)

		deferred_light_renderer_deinit(&renderer.deferred_renderer)

		deferred_ok: bool
		renderer.deferred_renderer, deferred_ok = deferred_light_renderer_init(
			&renderer.sprite_batch,
			renderer.window_size,
		)
		assert(deferred_ok, "failed to resize deferred renderer")

		renderer.deferred_renderer.gbuffer_shader = renderer.gbuffer_shader
		renderer.deferred_renderer.light_shader = renderer.light_shader
		renderer.deferred_renderer.composite_shader = renderer.composite_shader
	}
}
