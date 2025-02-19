package luna

import "assets"
import "base"
import "core"
import "gfx"
import "sfx"

import "core:fmt"
import "core:math"

import "vendor:glfw"


main :: proc() {

	app_run(
		app = &{
			setup_cb = setup,
			init_cb = init,
			update_cb = update,
			fixed_update_cb = fixed_update,
			draw_cb = draw,
			deinit_cb = deinit,
			title = "luna",
			update_per_seconds = 60,
		},
		render_pip = &{
			backend = gfx.supported_backend_e.opengl,
			view_mode = gfx.view_mode_e.two_d,
			clear_color = base.COLOR_CRIMSON,
			game_camera = {
				position   = base.vec2 { 	// [0, 0] on top left
					180,
					-90,
				},
				dimentions = base.vec2{360, 180},
				zoom       = 1,
			},
			window_size = {base.DEFAULT_WINDOW_WIDTH, base.DEFAULT_WINDOW_HEIGHT},
		},
		asset_pip = &{
			paths = {
				assets.asset_type_e.IMAGE = "assets/images/",
				assets.asset_type_e.SHADER = "assets/shaders/",
				assets.asset_type_e.FONT = "assets/fonts/",
				assets.asset_type_e.BAKED_FONT = "assets/fonts/baked/",
				assets.asset_type_e.SFX = "assets/sfx/",
				assets.asset_type_e.DATA = "assets/data/",
			},
		},
	)
}

audio: ^sfx.audio_t
wiwiwi_sound: ^sfx.sound_t
rat_dance_music: ^sfx.music_t

renderer: ^gfx.renderer_t
sprite_batch: ^gfx.batch_t

font_batch: ^gfx.batch_t
font: ^gfx.font_t

car_sprite: ^gfx.sprite_t
car_atlas: ^gfx.atlas_t

font_sprite: ^gfx.sprite_t
font_atlas: ^gfx.atlas_t

shader: ^gfx.shader_t
font_shader: ^gfx.shader_t
car_mat: gfx.material_t

setup :: proc(app: ^application_t) {}

init :: proc(app: ^application_t) {
	audio = sfx.audio_init()
	sfx.audio_set_volume(audio, .GENERAL, 0.1)
	wiwiwi_sound = sfx.sound_init(assets.get_path(.SFX, "wiwiwi.wav"), audio)
	rat_dance_music = sfx.music_init(assets.get_path(.SFX, "rat_dance_meme.wav"), .SINGLE, audio)

	renderer = gfx.renderer_init()
	gfx.renderer_update_camera(renderer, &gfx.pip.game_camera)
	shader = gfx.shader_init(
		assets.get_path(.SHADER, "test_no_tokens.glsl"),
		gfx.shader_type_e.SPRITE,
	)


	font_shader = gfx.shader_init(
		assets.get_path(.SHADER, "test_no_tokens.glsl"),
		gfx.shader_type_e.FONT,
	)

	car_mat = {
		color = {1, 1, 1, 0.5},
	}


	font = gfx.font_bake(
		assets.get_path(.FONT, "essential.ttf"),
		assets.get_path(.BAKED_FONT, "essential.png"),
		16,
		{128, 64},
	)

	font_sprite = gfx.sprite_from_png(assets.get_path(.BAKED_FONT, "essential.png"))
	font_atlas = gfx.atlas_init_from_font(font_sprite, font, 4)

	car_sprite = gfx.sprite_from_png(assets.get_path(.IMAGE, "test.png"))
	car_atlas = gfx.atlas_init(
		car_sprite,
		{0 = base.iaabb{0, 0, car_sprite.width, car_sprite.height}},
	)

	sprite_batch = gfx.batch_init(car_atlas, .SPRITE)
	font_batch = gfx.batch_init(font_atlas, .FONT)
}

deinit :: proc(app: ^application_t) {
	sfx.audio_deinit(audio)

	gfx.renderer_deinit(renderer)
	gfx.batch_deinit(sprite_batch)
	gfx.batch_deinit(font_batch)

	gfx.shader_deinit(shader)
	gfx.shader_deinit(font_shader)

	gfx.atlas_deinit(car_atlas)
	gfx.sprite_deinit(car_sprite)
}
prev_pos, pos: base.vec2

update :: proc(app: ^application_t, delta_time: f32) {
	sfx.audio_update_musics(audio)
}

fixed_update :: proc(app: ^application_t, fixed_delta_time: f32) {
	prev_pos = pos

	if core.inputs_key_down(.KEY_D) {pos.x += 100.0 * fixed_delta_time}
	if core.inputs_key_down(.KEY_A) {pos.x -= 100.0 * fixed_delta_time}
	if core.inputs_key_down(.KEY_S) {pos.y += 100.0 * fixed_delta_time}
	if core.inputs_key_down(.KEY_W) {pos.y -= 100.0 * fixed_delta_time}

	if core.inputs_key_pressed(.KEY_P) {
		sfx.sound_play(wiwiwi_sound)
	}

	if core.inputs_key_pressed(.KEY_M) {
		sfx.music_play(rat_dance_music)
	}

	if core.inputs_key_pressed(.KEY_N) {
		sfx.music_stop(rat_dance_music)
	}

	if core.inputs_key_pressed(.KEY_B) {
		sfx.music_reset(rat_dance_music)
	}

	pos += 100.0 * core.input.gamepad.left_stick * fixed_delta_time

	gfx.renderer_update_camera(renderer, &gfx.pip.game_camera)
}

draw :: proc(app: ^application_t, interpolated_delta_time: f32) {
	gfx.renderer_begin()

	gfx.renderer_use_shader(renderer, font_shader)
	gfx.batch_begin(font_batch)
	gfx.batch_add(
		font_batch,
		"yeeeet !!\nthis is a mother fucking text !",
		font,
		base.vec2{10, 100},
		base.vec2{1, 1},
		0,
		nil,
	)

	gfx.renderer_draw_batch(renderer, font_batch)

	gfx.renderer_use_shader(renderer, shader)
	gfx.batch_begin(sprite_batch)
	gfx.batch_add(
		sprite_batch,
		0,
		math.lerp(prev_pos, pos, interpolated_delta_time),
		base.vec2{2, 2},
		app.time * 32,
		&car_mat,
	)

	gfx.renderer_draw_batch(renderer, sprite_batch)
}
