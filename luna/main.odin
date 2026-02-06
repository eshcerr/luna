package luna

import "base"
import "core"
import "core/ecs"
import "core:debug/pe"
import "gfx"

engine := engine_t {
	title = "luna test",
	renderer_config = {
		window_provider = .GLFW,
		backend = .OPENGL,
		clear_color = base.COLOR_CORNFLOWER_BLUE,
		view_mode = .TWO_D,
		window_title = "luna test",
		window_width = 1280,
		window_height = 720,
		enable_editor = true,
		enable_deferred_lighting = true,
		vsync = false,
	},
	pipeline = engine_pipeline_t {
		callbacks = {
			setup_cb = setup,
			init_cb = init,
			deinit_cb = deinit,
			update_cb = update,
			fixed_update_cb = fixed_update,
			draw_cb = draw,
			build_editor_cb = editor,
		},
	},
}

main :: proc() {
	engine_run(&engine)
}

setup :: proc(engine: ^engine_t) {
	base.log_info("setup")
}

esh: ecs.entity_t

esh_texture: ^gfx.texture2D_t
esh_atlas: ^gfx.atlas_t

esh_sprite: ^gfx.sprite_renderer_t

init :: proc(engine: ^engine_t) {
	base.log_info("init")

	esh_texture = gfx.texture2D_init(
		"assets/images/car.png",
		.CLAMP_TO_EDGE,
		.NEAREST,
	)
	esh_atlas = gfx.atlas_init(
		esh_texture,
		{
			0 = gfx.atlas_rect_t {
				rect = {0, 0, esh_texture.dimensions.x, esh_texture.dimensions.y},
				pivot = {esh_texture.dimensions.x / 2, esh_texture.dimensions.y / 2},
			},
		},
	)

	esh = ecs.ecs_create_entity(engine.ecs, "esh")
	ecs.ecs_add_component(
		engine.ecs,
		esh,
		base.transform2D_t{position = {0, 0}, scale = {1, 1}},
	)
	ecs.ecs_add_component(
		engine.ecs,
		esh,
		gfx.sprite_renderer_t {
			atlas = esh_atlas,
			atlas_rect = 0,
			layer = 1,
			tint = base.COLOR_WHITE,
		},
	)

}

deinit :: proc(engine: ^engine_t) {
	base.log_info("deinit")

	gfx.atlas_deinit(esh_atlas)
	gfx.texture2D_deinit(esh_texture)
}

update :: proc(engine: ^engine_t, delta_time: f32) {
}

fixed_update :: proc(engine: ^engine_t, fixed_delta_time: f32) {
}

draw :: proc(engine: ^engine_t, interpolated_delta_time: f32) {
}

editor :: proc(engine: ^engine_t, delta_time: f32) {
}
