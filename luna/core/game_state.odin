package luna_core

game_state_t :: struct {
    // might move in an entity manager
    entities: [128]entity_t,
    latest_entity_handle: entity_handle_t
}

