package luna

import "base"
import "core"
import "gfx"

import "core:fmt"
import "core:math"

import "vendor:glfw"

main :: proc() {

	app_run(
		app = &{
			setup_cb = setup,
			init_cb = init,
			update_cb = update,
			draw_cb = draw,
			deinit_cb = deinit,
			title = "luna",
			update_per_seconds = 30,
		},
		pip = &{
			backend = gfx.supported_backend_e.opengl,
			view_mode = gfx.view_mode_e.two_d,
			clear_color = base.COLOR_CRIMSON,
			game_camera = {
				position   = base.vec2 { 	// [0, 0] on top left
					base.DEFAULT_WINDOW_WIDTH / 2,
					-base.DEFAULT_WINDOW_HEIGHT / 2,
				},
				dimentions = base.vec2{base.DEFAULT_WINDOW_WIDTH, base.DEFAULT_WINDOW_HEIGHT},
				zoom       = 1,
			},
			window_size = {base.DEFAULT_WINDOW_WIDTH, base.DEFAULT_WINDOW_HEIGHT},
		},
	)
}


renderer: gfx.renderer_t
batch: gfx.batch_t

car_sprite: gfx.sprite_t
car_atlas: gfx.atlas_t

shader: gfx.shader_t

setup :: proc(app: ^app_t) {}

init :: proc(app: ^app_t) {
	renderer = gfx.renderer_init()
	shader = gfx.shader_init("luna/ogl/shader.vert.glsl", "luna/ogl/shader.frag.glsl")

	car_sprite = gfx.sprite_from_png("luna/car.png")
	car_atlas = gfx.atlas_init(
		&car_sprite,
		{
			0 = base.iaabb{0, 0, 2, 2},
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

	gfx.atlas_deinit(&car_atlas)
	gfx.sprite_deinit(&car_sprite)
}
prev_pos, pos: base.vec2

update :: proc(app: ^app_t) {
	prev_pos = pos

	if core.inputs_key_down(.KEY_D) {pos.x += 100.0 * app.fixed_delta_time}
	if core.inputs_key_down(.KEY_A) {pos.x -= 100.0 * app.fixed_delta_time}
	if core.inputs_key_down(.KEY_S) {pos.y += 100.0 * app.fixed_delta_time}
	if core.inputs_key_down(.KEY_W) {pos.y -= 100.0 * app.fixed_delta_time}
}

draw :: proc(app: ^app_t, interpolated_delta_time: f32) {
	gfx.shader_use(&shader)

	gfx.renderer_begin()
	gfx.renderer_update_camera(&gfx.pip.game_camera)

	gfx.batch_begin(&batch)
	gfx.batch_add(&batch, 2, math.lerp(prev_pos, pos, interpolated_delta_time), base.vec2{1, 1})
	gfx.batch_add(&batch, 3, base.vec2{700, 700}, base.vec2{1, 1})

	gfx.renderer_draw_batch(&batch)
}
