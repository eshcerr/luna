package main

main :: proc() {
	app := app_t {
		title = "luna",
		setup_cb = setup,
		init_cb = init,
		update_cb = update,
		draw_cb = draw,
		deinit_cb = deinit,
		window = {width = 800, height = 600, bg_color = {0.1, 0.1, 0.2, 1.0}},
	}

	app_run(&app)
}

setup :: proc() {}
init :: proc() {}
update :: proc() {}
draw :: proc() {}
deinit :: proc() {}
