package luna

import "vendor:glfw"

running: bool = false

main :: proc() {
	running = platform_create_window({default_window_width, default_window_height}, "luna")
	for {
		if running == false {break}
		platform_update_window()
	}
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
	//renderer_draw(&renderer, &texture, &shader)
}
