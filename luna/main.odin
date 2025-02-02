package luna

import "base"
import "core"
import "gfx"

import "vendor:glfw"

main :: proc() {

	app_run(
		&{
			setup_cb = setup,
			init_cb = init,
			update_cb = update,
			draw_cb = draw,
			deinit_cb = deinit,
			title = "luna",
			window = {
				width = base.DEFAULT_WINDOW_WIDTH,
				height = base.DEFAULT_WINDOW_HEIGHT,
			},
			render_pipeline = {
				backend = gfx.supported_backend_e.opengl,
				view_mode = gfx.view_mode_e.two_d,
				clear_color = base.COLOR_CRIMSON
			},
		},
	)
}


renderer: gfx.renderer_t
car_sprite: core.sprite_t
texture: gfx.texture_t
shader: gfx.shader_t

setup :: proc(app: ^app_t) {}

init :: proc(app: ^app_t) {
	renderer = gfx.renderer_init()
	shader = gfx.shader_init("luna/ogl/shader.vert.glsl", "luna/ogl/shader.frag.glsl")
	car_sprite = core.sprite_from_png("luna/car.png")
	texture = gfx.texture_init(&car_sprite)
}

deinit :: proc(app: ^app_t) {
	gfx.renderer_deinit(&renderer)
	gfx.shader_deinit(&shader)
	gfx.texture_deinit(&texture)
	core.sprite_deinit(&car_sprite)
}

update :: proc(app: ^app_t) {}

draw :: proc(app: ^app_t) {
	gfx.shader_use(&shader)
	gfx.renderer_begin(&app.render_pipeline)
}
