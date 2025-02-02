package luna

import "base"
import "core"
import "gfx"

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


renderer: gfx.renderer_t
car_sprite: core.sprite_t
texture: gfx.texture_t
shader: gfx.shader_t

setup :: proc(app: ^core.app_t) {}

init :: proc(app: ^core.app_t) {
	renderer = gfx.renderer_init()
	shader = gfx.shader_init("luna/ogl/shader.vert.glsl", "luna/ogl/shader.frag.glsl")
	car_sprite = core.sprite_from_png("luna/car.png")
	texture = gfx.texture_init(&car_sprite)
}

deinit :: proc(app: ^core.app_t) {
	gfx.renderer_deinit(&renderer)
	gfx.shader_deinit(&shader)
	gfx.texture_deinit(&texture)
	core.sprite_deinit(&car_sprite)
}

update :: proc(app: ^core.app_t) {}

draw :: proc(app: ^core.app_t) {
	//renderer_draw(&renderer, &texture, &shader)
}
