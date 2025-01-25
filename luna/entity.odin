package luna

import "core:mem"

entity_flags_e :: enum {
	nil,
	allocated,
}

entity_kind_e :: enum {}

entity_handle_t :: u64
user_id_t :: u64

entity_t :: struct {
	id:      entity_handle_t,
	kind:    entity_kind_e,
	flags:   bit_set[entity_flags_e],
	pos:     vec2,
	vel:     vec2,
	acc:     vec2,
	user_id: user_id_t,
}

entity_create :: proc(gs: ^game_state_t) -> ^entity_t {
	spare_en: ^entity_t

	for &en in gs.entities {
		if !(.allocated in en.flags) {
			spare_en = &en
			break
		}
	}

	if spare_en == nil {
		// log err
		// ran out of entityes, increase size
		return nil
	} else {
		spare_en.flags = {.allocated}
		gs.latest_entity_handle += 1
		spare_en.id = gs.latest_entity_handle
		return spare_en
	}
}

entity_destroy :: proc(entity: ^entity_t) {
	mem.set(entity, 0, size_of(entity_t))
}
