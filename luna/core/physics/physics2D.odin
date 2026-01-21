package luna_physics

import "../../base"
import "../../utils"
import "core:fmt"
import "core:math"

collision_cb :: proc()
squish_cb :: proc()

aabb :: struct {
	min, max: base.vec2,
}

collider_t :: struct {
	aabb: aabb,
}

solid_flags_e :: enum (u8) {}

solid_t :: struct {
	collider:    collider_t,
	position:    base.vec2,
	velocity:    base.vec2,
	x_remainder: f32,
	y_remainder: f32,
	flags:       bit_set[solid_flags_e;u8],
	collidable:  b8,
}

actor_flags_e :: enum (u8) {}

actor_t :: struct {
	collider:    collider_t,
	position:    base.vec2,
	velocity:    base.vec2,
	x_remainder: f32,
	y_remainder: f32,
	riding_cb:   proc(solid: ^solid_t) -> bool,
	squish_cb:   proc(),
	flags:       bit_set[actor_flags_e;u8],
}

trigger_t :: struct {
	collider:    collider_t,
	position:    base.vec2,
	velocity:    base.vec2,
	x_remainder: f32,
	y_remainder: f32,
	on_enter_cb: proc(actor: ^actor_t, trigger: ^trigger_t),
	on_exit_cb:  proc(actor: ^actor_t, trigger: ^trigger_t),
	tracking:    [dynamic]^actor_t, //tracked actors
}

world_t :: struct {
	solids:   [dynamic]solid_t,
	actors:   [dynamic]actor_t,
	triggers: [dynamic]trigger_t,
}

world_create :: proc() -> ^world_t {
	world := new(world_t)
	world.actors = make([dynamic]actor_t)
	world.solids = make([dynamic]solid_t)
	world.triggers = make([dynamic]trigger_t)
	
	return world
}

world_deinit :: proc(world: ^world_t) {
	delete(world.actors)
	delete(world.solids)
	delete(world.triggers)
	free(world)
}

world_create_actor :: proc(world: ^world_t) -> u32 {
	actor := actor_t{}
	idx, err := append(&world.actors, actor)
	assert(err == .None, fmt.aprintf("cannot create actor: %e", err))
	return u32(idx)
}

world_get_actor :: proc(world: ^world_t, idx: u32) -> ^actor_t {
	assert(idx < u32(len(world.actors)), "index out of range")
	return &world.actors[idx]
}

world_delete_actor :: proc(world: ^world_t, idx: u32) {
	assert(idx < u32(len(world.actors)), "index out of range")
	if idx + 1 < u32(len(world.actors)) {
		world.actors[idx] = world.actors[len(world.actors) - 1]
	}
	pop(&world.actors)
}


world_create_solid :: proc(world: ^world_t) -> u32 {
	solid := solid_t{}
	idx, err := append(&world.solids, solid)
	assert(err == .None, fmt.aprintf("cannot create solid: %e", err))
	return u32(idx)
}

world_get_solid :: proc(world: ^world_t, idx: u32) -> ^solid_t {
	assert(idx < u32(len(world.solids)), "index out of range")
	return &world.solids[idx]
}

world_delete_solid :: proc(world: ^world_t, idx: u32) {
	assert(idx < u32(len(world.solids)), "index out of range")
	if idx + 1 < u32(len(world.solids)) {
		world.solids[idx] = world.solids[len(world.solids) - 1]
	}
	pop(&world.solids)
}


world_create_trigger :: proc(world: ^world_t) -> u32 {
	trigger := trigger_t{}
	idx, err := append(&world.triggers, trigger)
	assert(err == .None, fmt.aprintf("cannot create trigger: %e", err))
	return u32(idx)
}

world_get_trigger :: proc(world: ^world_t, idx: u32) -> ^trigger_t {
	assert(idx < u32(len(world.triggers)), "index out of range")
	return &world.triggers[idx]
}

world_delete_trigger :: proc(world: ^world_t, idx: u32) {
	assert(idx < u32(len(world.triggers)), "index out of range")
	if idx + 1 < u32(len(world.triggers)) {
		world.triggers[idx] = world.triggers[len(world.triggers) - 1]
	}
	pop(&world.triggers)
}


get_aabb_at :: proc(position: base.vec2, collider: ^collider_t) -> aabb {
	return aabb{min = position + collider.aabb.min, max = position + collider.aabb.max}
}

aabb_overlaps :: proc(a: aabb, b: aabb) -> bool {
	return !(a.max.x < b.min.x || a.min.x > b.max.x || a.max.y < b.min.y || a.min.y > b.max.y)
}

collide_at :: proc(position: base.vec2, collider: ^collider_t, solids: []solid_t) -> bool {
	test_aabb := get_aabb_at(position, collider)
	for &s in solids {
		if !s.collidable do continue
		if aabb_overlaps(test_aabb, get_aabb_at(s.position, &s.collider)) {
			return true
		}
	}
	return false
}

colision_overlaps :: proc(actor: ^actor_t, solid: ^solid_t) -> bool {
	return aabb_overlaps(
		get_aabb_at(actor.position, &actor.collider),
		get_aabb_at(solid.position, &solid.collider),
	)
}

actor_move_x :: proc(actor: ^actor_t, amount: f32, on_collide: collision_cb, solids: []solid_t) {
	actor.x_remainder += amount
	move := i32(math.round(actor.x_remainder))
	if move != 0 {
		actor.x_remainder -= f32(move)
		sign := math.sign(f32(move))
		for move != 0 {
			if !collide_at(actor.position + {f32(sign), 0}, &actor.collider, solids) {
				actor.position.x += f32(sign)
				move -= i32(sign)
			} else {
				if on_collide != nil do on_collide()
				break
			}
		}
	}
}

actor_move_y :: proc(actor: ^actor_t, amount: f32, on_collide: collision_cb, solids: []solid_t) {
	actor.y_remainder += amount
	move := i32(math.round(actor.y_remainder))
	if move != 0 {
		actor.y_remainder -= f32(move)
		sign := math.sign(f32(move))
		for move != 0 {
			if !collide_at(actor.position + {0, f32(sign)}, &actor.collider, solids) {
				actor.position.y += f32(sign)
				move -= i32(sign)
			} else {
				if on_collide != nil do on_collide()
				break
			}
		}
	}
}


solid_get_riding_actor :: proc(solid: ^solid_t, actors: []actor_t) -> [dynamic]^actor_t {
	riding: [dynamic]^actor_t
	for &a in actors {
		if a.riding_cb != nil && a.riding_cb(solid) {
			append(&riding, &a)
		}
	}
	return riding
}

solid_move :: proc(solid: ^solid_t, x: f32, y: f32, actors: []actor_t, solids: []solid_t) {
	solid.x_remainder += x
	solid.y_remainder += y
	move_x := i32(math.round(solid.x_remainder))
	move_y := i32(math.round(solid.y_remainder))
	if move_x != 0 || move_y != 0 {
		riding := solid_get_riding_actor(solid, actors)
		defer delete(riding)

		solid.collidable = false

		if move_x != 0 {
			solid.x_remainder -= f32(move_x)
			solid.position.x += f32(move_x)
			sign_x := math.sign(f32(move_x))
			for &a in actors {
				if colision_overlaps(&a, solid) {
					push_amount: f32
					if sign_x > 0 {
						push_amount =
							(solid.position.x + solid.collider.aabb.max.x) -
							(a.position.x + a.collider.aabb.min.x)
					} else {
						push_amount =
							(solid.position.x + solid.collider.aabb.min.x) -
							(a.position.x + a.collider.aabb.max.x)
					}
					actor_move_x(&a, push_amount, a.squish_cb, solids)
				} else {
					for r in riding {
						if &a == r {
							actor_move_x(&a, f32(move_x), nil, solids)
							break
						}
					}
				}
			}
		}

		if move_y != 0 {
			solid.y_remainder -= f32(move_y)
			solid.position.y += f32(move_y)
			sign_y := math.sign(f32(move_y))
			for &a in actors {
				if colision_overlaps(&a, solid) {
					push_amount: f32
					if sign_y > 0 {
						push_amount =
							(solid.position.y + solid.collider.aabb.max.y) -
							(a.position.y + a.collider.aabb.min.y)
					} else {
						push_amount =
							(solid.position.y + solid.collider.aabb.min.y) -
							(a.position.y + a.collider.aabb.max.y)
					}
					actor_move_y(&a, push_amount, a.squish_cb, solids)
				} else {
					for r in riding {
						if &a == r {
							actor_move_x(&a, f32(move_y), nil, solids)
							break
						}
					}
				}
			}
		}

		solid.collidable = true
	}
}

trigger_move :: proc(trigger: ^trigger_t, x: f32, y: f32, actors: []actor_t) {
	trigger.x_remainder += x
	trigger.y_remainder += y
	move_x := i32(math.round(trigger.x_remainder))
	move_y := i32(math.round(trigger.y_remainder))

	if move_x != 0 || move_y != 0 {
		trigger.x_remainder -= f32(move_x)
		trigger.y_remainder -= f32(move_y)
		trigger.position.x += f32(move_x)
		trigger.position.y += f32(move_y)

		current: [dynamic]^actor_t
		defer delete(current)

		for &a in actors {
			if aabb_overlaps(a.collider.aabb, trigger.collider.aabb) {
				append(&current, &a)
			}
		}

		for a in trigger.tracking {
			if !utils.dynamic_array_contains_ptr(&current, a) && trigger.on_exit_cb != nil {
				trigger.on_exit_cb(a, trigger)
			}
		}

		for a in current {
			if !utils.dynamic_array_contains_ptr(&trigger.tracking, a) &&
			   trigger.on_enter_cb != nil {
				trigger.on_enter_cb(a, trigger)
			}
		}

		clear(&trigger.tracking)
		reserve(&trigger.tracking, len(current))
		for a in current {
			append(&trigger.tracking, a)
		}
	}
}
