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

setup :: proc(app: ^app_t) {
	glfw.WindowHint(glfw.TRANSPARENT_FRAMEBUFFER, true)
	glfw.WindowHint(glfw.AUTO_ICONIFY, false)
	glfw.WindowHint(glfw.SCALE_FRAMEBUFFER, false)
	
	glfw.WindowHint(glfw.DECORATED, false)
}

init :: proc(app: ^app_t) {
	glfw.SetWindowPos(app.window.handle, 0, -1)
	glfw.SetWindowSize(app.window.handle, 1920, 1081)
}
update :: proc(app: ^app_t) {}
draw :: proc(app: ^app_t) {}
deinit :: proc(app: ^app_t) {}
