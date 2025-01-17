package main

import "vendor:glfw"

main :: proc() {
	app := app_t {
		title = "luna",
		setup_cb = setup,
		init_cb = init,
		update_cb = update,
		draw_cb = draw,
		deinit_cb = deinit,
		window = {width = 800, height = 600, bg_color = {0.0, 0.0, 1.0, 0.0}},
	}

	app_run(&app)
}

car_sprite: ^png.Image
texture: texture_t
shader: shader_t

setup :: proc(app: ^app_t) {
	glfw.WindowHint(glfw.TRANSPARENT_FRAMEBUFFER, true)
	glfw.WindowHint(glfw.AUTO_ICONIFY, false)
	glfw.WindowHint(glfw.SCALE_FRAMEBUFFER, false)
	
	glfw.WindowHint(glfw.DECORATED, false)
}

init :: proc(app: ^app_t) {
	mode := glfw.GetVideoMode(glfw.GetPrimaryMonitor())

	glfw.SetWindowPos(app.window.handle, 0, -1)
	glfw.SetWindowSize(app.window.handle, mode.width, mode.height + 1)

	renderer = renderer_init()
	shader = shader_init(#load("shader.vert.glsl"), #load("shader.frag.glsl"))
	err: png.Error
	car_sprite, err = png.load_from_file("luna/car.png")
	texture = texture_init(car_sprite)
}

update :: proc(app: ^app_t) {}

draw :: proc(app: ^app_t) {
	renderer_draw(&renderer, &texture, &shader)
}

deinit :: proc(app: ^app_t) {
	renderer_deinit(&renderer)
	shader_deinit(&shader)
	texture_deinit(&texture)
	png.destroy(car_sprite)
}
