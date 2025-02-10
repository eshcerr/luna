package luna_gfx

import "../base"

camera_mode_t :: enum {
	orthographic,
	perspective,
}

camera_t :: struct {
	mode:                 camera_mode_t,
	position, dimentions: base.vec2,
	zoom:                 f32,
}

camera_projection :: proc(camera: ^camera_t) -> base.mat4 {
	return base.mat4_orthographic_projection(
		(camera.position.x - camera.dimentions.x / 2) / camera.zoom,
		(camera.position.x + camera.dimentions.x / 2) / camera.zoom,
		(camera.position.y - camera.dimentions.y / 2) / camera.zoom,
		(camera.position.y + camera.dimentions.y / 2) / camera.zoom,
	)
}

camera_screen_to_world :: proc(screen_pos: base.ivec2) -> base.vec2 {
	position := base.ivec2_to_vec2(screen_pos) / base.ivec2_to_vec2(pip.window_size) * pip.game_camera.dimentions
	position += -pip.game_camera.dimentions / 2.0 - pip.game_camera.position
    return position
}
