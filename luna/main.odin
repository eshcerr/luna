package luna

import "base"
import "core"
import "os"
import "ogl"

import "vendor:glfw"

main :: proc() {
	using os
	running = platform_create_window([]i32{base.default_window_width, base.default_window_height}, "luna")
	for {
		if running == false {break}
		platform_update_window()
	}
}


renderer: ogl.renderer_t

car_sprite: ogl.sprite_t
texture: ogl.texture_t
shader: ogl.shader_t

setup :: proc(app: ^core.app_t) {}

init :: proc(app: ^core.app_t) {
	using ogl
	renderer = renderer_init()
	shader = shader_init("luna/ogl/shader.vert.glsl", "luna/ogl/shader.frag.glsl")
	car_sprite = sprite_from_png("luna/car.png")
	texture = texture_init(&car_sprite)
}

deinit :: proc(app: ^core.app_t) {
	using ogl
	renderer_deinit(&renderer)
	shader_deinit(&shader)
	texture_deinit(&texture)
	sprite_deinit(&car_sprite)
}

update :: proc(app: ^core.app_t) {}

draw :: proc(app: ^core.app_t) {
	//renderer_draw(&renderer, &texture, &shader)
}
