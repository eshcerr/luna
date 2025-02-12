package luna_core

import "../base"

import "core:mem"

entity_flags_e :: enum {
	nil,
	ALLOCATED,
}

entity_kind_e :: enum {}

entity_handle_t :: u64
user_id_t :: u64

entity_t :: struct {
	id:       entity_handle_t,
	kind:     entity_kind_e,
	flags:    bit_set[entity_flags_e],
	user_id:  user_id_t,
}

entity_create :: proc(gs: ^game_state_t) -> ^entity_t {
	spare_en: ^entity_t

	for &en in gs.entities {
		if !(.ALLOCATED in en.flags) {
			spare_en = &en
			break
		}
	}

	assert(spare_en != nil, "ran out of entities, increase size")

	spare_en.flags = {.ALLOCATED}
	gs.latest_entity_handle += 1
	spare_en.id = gs.latest_entity_handle
	return spare_en
}

entity_destroy :: proc(entity: ^entity_t) {
	mem.set(entity, 0, size_of(entity_t))
}
