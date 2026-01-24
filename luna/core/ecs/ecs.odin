package luna_ecs

import "core:encoding/entity"
import "core:strconv/decimal"
entity_t :: distinct u32

ecs_t :: struct {
	next_entity:    entity_t,
	components:     map[typeid]component_storage_t,
	entity_to_name: map[entity_t]string,
}

component_storage_t :: struct {
	data:            [dynamic]rawptr,
	entities:        [dynamic]entity_t,
	entity_to_index: map[entity_t]int,
}

ecs_init :: proc() -> ^ecs_t {
	ecs := new(ecs_t)
	ecs.next_entity = 1
	ecs.components = make(map[typeid]component_storage_t)
	ecs.entity_to_name = make(map[entity_t]string)
	return ecs
}

ecs_deinit :: proc(ecs: ^ecs_t) {
	for _, &storage in ecs.components {
		for ptr in storage.data {
			free(ptr)
		}
		delete(storage.data)
		delete(storage.entities)
		delete(storage.entity_to_index)
	}
	delete(ecs.entity_to_name)
	delete(ecs.components)
}

ecs_add_component :: proc(ecs: ^ecs_t, entity: entity_t, component: $T) {
	type_id := typeid_of(T)

	if type_id not_in ecs.components {
		ecs.components[type_id] = component_storage_t {
			data            = make([dynamic]rawptr),
			entities        = make([dynamic]entity_t),
			entity_to_index = make(map[entity_t]int),
		}
	}

	storage := &ecs.components[type_id]

	ptr := new(T)
	ptr^ = component

	index := len(storage.data)
	append(&storage.data, ptr)
	append(&storage.entities, entity)
	storage.entity_to_index[entity] = index
}

ecs_get_component :: proc(ecs: ^ecs_t, entity: entity_t, $T: typeid) -> ^T {
	type_id := typeid_of(T)

	storage, ok := ecs.components[type_id]
	if !ok do return nil

	index, found := storage.entity_to_index[entity]
	if !found do return nil

	return (^T)(storage.data[index])
}

ecs_has_component :: proc(ecs: ^ecs_t, entity: entity_t, $T: typeid) -> bool {
	_, ok := ecs.components[type_id]
	return ok
}

ecs_remove_component :: proc(ecs: ^ecs_t, entity: entity_t, $T: typeid) {
	type_id := typeid_of(T)

	storage, ok := &ecs.components[type_id]
	if !ok do return

	index, found := storage.entity_to_index[entity]
	if !found do return

	// Free the component
	free(storage.data[index])

	// Swap and pop (faster than ordered_remove)
	last_index := len(storage.data) - 1
	if index != last_index {
		// Move last element to this position
		storage.data[index] = storage.data[last_index]
		storage.entities[index] = storage.entities[last_index]
		// Update the moved entity's index
		storage.entity_to_index[storage.entities[index]] = index
	}

	pop(&storage.data)
	pop(&storage.entities)
	delete_key(&storage.entity_to_index, entity)
}

ecs_create_entity :: proc(ecs: ^ecs_t, name: string = "") -> entity_t {
	entity := ecs.next_entity
	ecs.next_entity += 1

	if name != "" {
		ecs.entity_to_name[entity] = name
	}
	
	return entity
}

ecs_destroy_entity :: proc(ecs: ^ecs_t, entity: entity_t) {
	if _, exists := ecs.entity_to_name[entity]; exists {
		delete_key(&ecs.entity_to_name, entity)
	}

	for type_id, &storage in ecs.components {
		index, found := storage.entity_to_index[entity]
		if !found do continue

		// Free the component
		free(storage.data[index])

		// Swap and pop
		last_index := len(storage.data) - 1
		if index != last_index {
			storage.data[index] = storage.data[last_index]
			storage.entities[index] = storage.entities[last_index]
			storage.entity_to_index[storage.entities[index]] = index
		}

		pop(&storage.data)
		pop(&storage.entities)
		delete_key(&storage.entity_to_index, entity)
	}
}


ecs_query :: proc(ecs: ^ecs_t, types: ..typeid) -> [dynamic]entity_t {
	results := make([dynamic]entity_t)

	if len(types) == 0 do return results

	// Get the smallest component storage as our base
	smallest_storage: ^component_storage_t
	smallest_count := max(int)

	for type_id in types {
		storage, ok := &ecs.components[type_id]
		if !ok {
			// If any component type doesn't exist, no entities can have all of them
			return results
		}
		if len(storage.entities) < smallest_count {
			smallest_count = len(storage.entities)
			smallest_storage = storage
		}
	}

	// Check each entity in the smallest storage
	entity_loop: for entity in smallest_storage.entities {
		// Check if this entity has all required components
		for type_id in types {
			storage := &ecs.components[type_id]
			if entity not_in storage.entity_to_index {
				continue entity_loop
			}
		}
		// Entity has all components!
		append(&results, entity)
	}

	return results
}
