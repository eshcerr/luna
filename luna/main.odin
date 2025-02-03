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
			window = {width = base.DEFAULT_WINDOW_WIDTH, height = base.DEFAULT_WINDOW_HEIGHT},
			render_pipeline = {
				backend = gfx.supported_backend_e.opengl,
				view_mode = gfx.view_mode_e.two_d,
				clear_color = base.COLOR_CRIMSON,
			},
		},
	)
}


renderer: gfx.renderer_t
batch: gfx.batch_t

car_sprite: core.sprite_t
car_atlas: core.atlas_t

shader: gfx.shader_t

setup :: proc(app: ^app_t) {}

init :: proc(app: ^app_t) {
	renderer = gfx.renderer_init()
	shader = gfx.shader_init("luna/ogl/shader.vert.glsl", "luna/ogl/shader.frag.glsl")

	car_sprite = core.sprite_from_png("luna/car.png")
	car_atlas = core.atlas_init(
		&car_sprite,
		{
			0 = base.iaabb{0, 0, 500, 500},
			1 = base.iaabb{500, 0, 500, 500},
			2 = base.iaabb{0, 500, 500, 500},
			3 = base.iaabb{500, 500, 500, 500},
		},
	)

	batch = gfx.batch_init(&car_atlas)
}

deinit :: proc(app: ^app_t) {
	gfx.renderer_deinit(&renderer)
	gfx.batch_deinit(&batch)

	gfx.shader_deinit(&shader)

	core.atlas_deinit(&car_atlas)
	core.sprite_deinit(&car_sprite)
}

update :: proc(app: ^app_t) {}

draw :: proc(app: ^app_t) {
	gfx.renderer_begin(&app.render_pipeline)

	gfx.shader_use(&shader)
	gfx.shader_set_vec2(&shader, "screen_size", base.vec2{f32(app.window.width), f32(app.window.height)})

	gfx.batch_begin(&batch)
	gfx.batch_add(&batch, 2, base.vec2{50, 100}, base.vec2{1, 1})
	gfx.batch_add(&batch, 3, base.vec2{600, 100}, base.vec2{1, 1})

	gfx.renderer_draw_batch(&batch)
}
