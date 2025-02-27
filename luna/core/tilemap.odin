package luna_core

import "../base"

// bitmask here
//https://code.tutsplus.com/how-to-use-tile-bitmasking-to-auto-tile-your-level-layouts--cms-25673t
tile_t :: struct {
	id:              u32,
	neighbours_mask: u8,
	is_visible:      bool,
}

tilemap_t :: struct {
	position:  base.ivec2,
	grid_size: base.ivec2,
	data:      [][]tile_t,
	tile_size: base.ivec2,
}

tilemap_init :: proc(grid_size, tile_size, position: base.ivec2) -> ^tilemap_t {
	tilemap: new(tilemap_t)
	tilemap.grid_size = grid_size
	tilemap.tile_size = tile_size

	tilemap.data = make([][]tile_t, grid_size.x)
	for i in 0 ..< grid_size.x {
		tilemap.data[i] = make([]tile_t, grid_size.y)
	}
	return tilemap
}

tilemap_deinit :: proc(tilemap: ^tilemap_t) {
	for &row in tilemap.data {
		free(&row)
	}
	free(&tilemap.data)
	tilemap.data = nil
}

tilemap_get_tile :: proc(tilemap: ^tilemap_t, x, y: i32) -> ^tile_t {
	assert(
		x >= tilemap.position.x &&
		x < tilemap.grid_size.x + tilemap.position.x / tilemap.tile_size.x &&
		y >= tilemap.position.y &&
		y < tilemap.grid_size.y + tilemap.position.y / tilemap.tile_size.y,
		"Out of grid",
	)
	return &tilemap.data[x][y]
}

tilemap_get_tile_from_world :: proc(tilemap: ^tilemap_t, world_position: base.ivec2) -> ^tile_t {
	return tilemap_get_tile(
		tilemap,
		world_position.x / tilemap.tile_size.x,
		world_position.y / tilemap.tile_size.y,
	)
}
