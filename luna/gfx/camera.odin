package luna_gfx

import "../base"
import "core:math"
import "core:math/linalg"

camera_mode_t :: enum {
	orthographic,
	perspective,
}

camera_t :: struct {
	mode:                 camera_mode_t,
	position, dimentions: base.vec2,
	rotation, zoom:       f32,
}

// TODO : implement camera zoom
camera_projection :: proc(camera: ^camera_t) -> base.mat4 {

	translate, rotate, ortho: base.mat4
	translate = linalg.matrix4_translate_f32({camera.position.x, camera.position.y, 0})
	rotate = linalg.matrix4_rotate_f32(math.to_radians_f32(camera.rotation), {0, 0, 1})

	ortho = linalg.matrix_ortho3d_f32(
		camera.position.x - camera.dimentions.x / 2.0,
		camera.position.x + camera.dimentions.x / 2.0,
		camera.position.y - camera.dimentions.y / 2.0,
		camera.position.y + camera.dimentions.y / 2.0,
		1,
		-1,
	)

	ortho = linalg.mul(ortho, translate)
	ortho = linalg.mul(ortho, rotate)
	ortho = linalg.mul(ortho, linalg.inverse(translate))

	return ortho
}

camera_screen_to_world :: proc(camera: ^camera_t, screen_pos: base.ivec2) -> base.vec2 {
	position :=
		base.ivec2_to_vec2(screen_pos) / base.ivec2_to_vec2(pip.window_size) * camera.dimentions
	position += -camera.dimentions / 2.0 + (camera.position * base.vec2{1, -1})
	return position
}
