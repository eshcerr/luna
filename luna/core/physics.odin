package luna_core

import "../base"
import "core:math"

MAX_CONTACT_REPORTED :: 8

physics_t :: struct {}

body_type_e :: enum {
	STATIC,
	DYNAMIC,
	KINEMATIC,
}

body_flags_e :: enum (u8) {
	nil,
	CAN_SLEEP,
	SLEEPING,
	FREEZE,
	LOCK_ROTATION,
	LINEAR_DAMP_REPLACE,
	ANGULAR_DAMP_REPLACE,
	CENTER_OF_MASS_CUSTOM,
}

collider_handle_t :: distinct u32

rigidbody2D_t :: struct {
	position, linear_vel, center_of_mass:   base.vec2,
	inertia, gravity_scale, mass:           f32,
	linear_damp, angular_damp, angular_vel: f32,
	collider:                               collider_handle_t,
	flags:                                  bit_set[body_flags_e],
}


static_collider_t :: struct {
	aabb:       base.iaabb,
	layer_mask: u32,
}

dynamic_collider_t :: struct {
	offset:     base.vec2,
	shape:      union {
		base.aabb,
		base.circle,
	},
	layer_mask: u32,
	shape_type: enum {
		AABB,
		CIRCLE,
	},
}

world_t :: struct {
	dynamic_bodies:   [dynamic]rigidbody2D_t,
	kinematic_bodies: [dynamic]rigidbody2D_t,
	bodies_colliders: [dynamic]dynamic_collider_t,
	static_colliders: [dynamic]static_collider_t,
}

collision_contact_t :: struct {
	normal:       base.vec2,
	a_idx, b_idx: u32,
	penetration:  f32,
}

//register_body :: proc(
//	world: ^world_t,
//	body: rigidbody2D_t,
//	body_type: body_type_e,
//) -> ^rigidbody2D_t {
//}

rigidbody2D_register :: proc(body: ^rigidbody2D_t, body_type: body_type_e, world: ^world_t) {
	if (body_type == .DYNAMIC) {
		append_elem(&world.dynamic_bodies, body^)
	} else if (body_type == .KINEMATIC) {
		append_elem(&world.kinematic_bodies, body^)
	}
}

rigidbody2D_deinit :: proc(body: ^rigidbody2D_t) {

}

rigidbody2D_attach_collider :: proc(
	body: ^rigidbody2D_t,
	collider: dynamic_collider_t,
	world: ^world_t,
) {
	index, is_ok := append_elem(&world.bodies_colliders, collider)
	assert(is_ok != .None, "failed to insert collider to rigidbody2D")
	body.collider = auto_cast index
}

physics_step :: proc(world: ^world_t, dt: f32) {

}

physics_integrate_dynamics :: proc(world: ^world_t, dt: f32) {

}
