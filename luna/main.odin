//#+feature dynamic-literals
package luna 

import "core:log"
import "assets"
import "base"
import "core"
import "gfx"
import "sfx"
import "core/physics"

import "core:fmt"
import "core:math"


main :: proc() {
	pipeline := new(application_pipeline_t)

	pipeline.callbacks =
	&{
		setup_cb = setup,
		init_cb = init,
		update_cb = update,
		fixed_update_cb = fixed_update,
		draw_cb = draw,
		deinit_cb = deinit,
	}

	pipeline.render =
	&{
		window_provider = gfx.window_provider_e.GLFW,
		backend = gfx.supported_backend_e.OPENGL,
		view_mode = gfx.view_mode_e.TWO_D,
		clear_color = base.COLOR_CORNFLOWER_BLUE,
		game_camera = {position = base.vec2{160, -90}, dimentions = base.vec2{320, 180}, zoom = 1},
		ui_camera = {position = base.vec2{160, -90}, dimentions = base.vec2{320, 180}, zoom = 1},
		window_size = {base.DEFAULT_WINDOW_WIDTH, base.DEFAULT_WINDOW_HEIGHT},
	}

	pipeline.asset =
	&{
		paths = {
			.IMAGE = "assets/images/",
			.SHADER = "assets/shaders/",
			.FONT = "assets/fonts/",
			.BAKED_FONT = "assets/fonts/baked/",
			.SFX = "assets/sfx/",
			.DATA = "assets/data/",
		},
	}

	app_run(app = &{title = "luna", pipeline = pipeline, time = {update_per_second = 60}})
}

wiwiwi_sound: ^sfx.sound_t
rat_dance_music: ^sfx.music_t

renderer: ^gfx.renderer_t
sprite_batch: ^gfx.batch_t

font_batch: ^gfx.batch_t
font: ^gfx.font_t

car_sprite: ^gfx.sprite_t
car_atlas: ^gfx.atlas_t

esh_sprite: ^gfx.sprite_t
esh_atlas: ^gfx.atlas_t
esh_sprite_batch: ^gfx.batch_t


font_sprite: ^gfx.sprite_t
font_atlas: ^gfx.atlas_t

shader: ^gfx.shader_t
font_shader: ^gfx.shader_t
car_mat: gfx.material_t

physics_world: ^physics.world_t
esh_actor: ^physics.actor_t
ground_solid: ^physics.solid_t

setup :: proc(app: ^application_t) {}

init :: proc(app: ^application_t) {
	sfx.audio_set_volume(sfx.audio, .GLOBAL, 0.1)
	wiwiwi_sound = sfx.sound_init(assets.get_path(.SFX, "wiwiwi.wav"), sfx.audio)
	rat_dance_music = sfx.music_init(
		assets.get_path(.SFX, "rat_dance_meme.wav"),
		.LOOP,
		sfx.audio,
	)

	renderer = gfx.renderer_init()
	renderer.global_light.color = base.COLOR_WHITE.rgb
	
	gfx.renderer_use_camera(renderer, &gfx.pip.game_camera)

	shader = gfx.shader_init(
		assets.get_path(.SHADER, "test_no_tokens.glsl"),
		gfx.shader_type_e.SPRITE,
	)

	font_shader = gfx.shader_init(
		assets.get_path(.SHADER, "test_no_tokens.glsl"),
		gfx.shader_type_e.FONT,
	)

	font = gfx.font_bake(
		assets.get_path(.FONT, "essential.ttf"),
		assets.get_path(.BAKED_FONT, "essential.png"),
		16,
		{128, 64},
	)

	font_sprite = gfx.sprite_from_png(assets.get_path(.BAKED_FONT, "essential.png"))
	font_atlas = gfx.atlas_init_from_font(font_sprite, font, 4)

	car_sprite = gfx.sprite_from_png(assets.get_path(.IMAGE, "car.png"))
	car_atlas = gfx.atlas_init(
		car_sprite,
		{0 = base.iaabb{0, 0, car_sprite.width, car_sprite.height}},
	)

	esh_sprite = gfx.sprite_from_png(assets.get_path(.IMAGE, "silksong_scared_esh.png"))
	esh_atlas = gfx.atlas_init(
		esh_sprite,
		{0 = base.iaabb{0, 0, esh_sprite.width, esh_sprite.height}},
	)
	fmt.println(esh_sprite.width, "|", esh_sprite.width)

	sprite_batch = gfx.batch_init(car_atlas, .SPRITE)
	esh_sprite_batch = gfx.batch_init(esh_atlas, .SPRITE)
	font_batch = gfx.batch_init(font_atlas, .FONT)

	physics_world = physics.world_create()
}

deinit :: proc(app: ^application_t) {
	sfx.sound_deinit(wiwiwi_sound, sfx.audio)
	sfx.music_deinit(rat_dance_music, sfx.audio)

	gfx.renderer_deinit(renderer)
	gfx.batch_deinit(sprite_batch)
	gfx.batch_deinit(esh_sprite_batch)
	gfx.batch_deinit(font_batch)

	gfx.shader_deinit(shader)
	gfx.shader_deinit(font_shader)

	gfx.atlas_deinit(car_atlas)
	gfx.sprite_deinit(car_sprite)

	gfx.atlas_deinit(esh_atlas)
	gfx.sprite_deinit(esh_sprite)

	physics.world_deinit(physics_world)
}
prev_pos, pos: base.vec2
esh_pos, esh_prev_pos : base.vec2

update :: proc(app: ^application_t, delta_time: f32) {
}

fixed_update :: proc(app: ^application_t, fixed_delta_time: f32) {
	prev_pos = pos
	esh_prev_pos = esh_pos

	if core.inputs_key_down(.KEY_D) {esh_pos.x += 100.0 * fixed_delta_time}
	if core.inputs_key_down(.KEY_A) {esh_pos.x -= 100.0 * fixed_delta_time}
	if core.inputs_key_down(.KEY_W) {esh_pos.y += 100.0 * fixed_delta_time}
	if core.inputs_key_down(.KEY_S) {esh_pos.y -= 100.0 * fixed_delta_time}

	fmt.println(esh_pos, "|", app.pipeline.render.game_camera.position)

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
}

draw :: proc(app: ^application_t, interpolated_delta_time: f32) {
	gfx.renderer_begin()
	gfx.renderer_use_camera(renderer, &gfx.pip.ui_camera)

	gfx.renderer_use_shader(renderer, font_shader)
	gfx.batch_begin(font_batch)
	gfx.batch_add(
		font_batch,
		"yeeeet !!\nthis is a mother fucking text !",
		font,
		base.ivec2{100, 100},
        base.vec2{1, 1},
	)

	gfx.renderer_draw_batch(renderer, font_batch)

	// gfx.renderer_use_camera(renderer, &gfx.pip.game_camera)
	// gfx.renderer_use_shader(renderer, shader)
	// gfx.batch_begin(sprite_batch)
	// gfx.batch_add(
	// 	sprite_batch,
	// 	0,
	// 	base.vec2_to_ivec2(math.lerp(prev_pos, pos, interpolated_delta_time)),
	// 	base.ivec2{360, 360},
	// 	base.vec2{1, 1},
	// )

	// gfx.renderer_draw_batch(renderer, sprite_batch)
	
	gfx.renderer_use_camera(renderer, &gfx.pip.game_camera)
	gfx.renderer_use_shader(renderer, shader)
	gfx.batch_begin(esh_sprite_batch)
	gfx.batch_add(
		esh_sprite_batch,
		0,
		base.vec2_to_ivec2(math.lerp(esh_prev_pos, esh_pos, interpolated_delta_time)),
		base.ivec2{24, 24},
		base.vec2{1, 1},
	)

	gfx.renderer_draw_batch(renderer, esh_sprite_batch)
}
