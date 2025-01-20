package luna

import "vendor:glfw"

main :: proc() {
	app := app_t {
		title = "luna",
		setup_cb = setup,
		init_cb = init,
		update_cb = update,
		draw_cb = draw,
		deinit_cb = deinit,
		window = {width = 800, height = 600, bg_color = {0.3, 0.0, 0.2, 1.0}},
	}

	app_run(&app)
}

renderer: renderer_t

car_sprite: sprite_t
texture: texture_t
shader: shader_t

setup :: proc(app: ^app_t) {}

init :: proc(app: ^app_t) {
	renderer = renderer_init()
	shader = shader_init("luna/shader.vert.glsl", "luna/shader.frag.glsl")
	car_sprite = sprite_from_png("luna/car.png")
	texture = texture_init(&car_sprite)
}

deinit :: proc(app: ^app_t) {
	renderer_deinit(&renderer)
	shader_deinit(&shader)
	texture_deinit(&texture)
	sprite_deinit(&car_sprite)
}

update :: proc(app: ^app_t) {}

draw :: proc(app: ^app_t) {
	renderer_draw(&renderer, &texture, &shader)
}
