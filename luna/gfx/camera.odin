package luna_gfx

import "../base"

import "core:math/linalg"

camera_t :: struct {
	position: base.vec3,
	forward:  base.vec3,
	up:       base.vec3,
	right:    base.vec3,
	world_up: base.vec3,
	yaw:      f32,
	pitch:    f32,
	zoom:     f32,
}

camera_get_view_mat :: proc(camera: ^camera_t) -> base.mat4 {
	return linalg.matrix4_look_at_f32(camera.position, camera.position + camera.front, camera.up)
}
