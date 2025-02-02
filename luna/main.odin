package luna

import "base"
import "core"
import "ogl"

import "vendor:glfw"

main :: proc() {

	core.app_run(
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
				bg_color = base.COLOR_AQUA,
			},
		},
	)
}


renderer: ogl.renderer_t
car_sprite: ogl.sprite_t
texture: ogl.texture_t
shader: ogl.shader_t

setup :: proc(app: ^core.app_t) {}

init :: proc(app: ^core.app_t) {
	renderer = ogl.renderer_init()
	shader = ogl.shader_init("luna/ogl/shader.vert.glsl", "luna/ogl/shader.frag.glsl")
	car_sprite = ogl.sprite_from_png("luna/car.png")
	texture = ogl.texture_init(&car_sprite)
}

deinit :: proc(app: ^core.app_t) {
	ogl.renderer_deinit(&renderer)
	ogl.shader_deinit(&shader)
	ogl.texture_deinit(&texture)
	ogl.sprite_deinit(&car_sprite)
}

update :: proc(app: ^core.app_t) {}

draw :: proc(app: ^core.app_t) {
	//renderer_draw(&renderer, &texture, &shader)
}
