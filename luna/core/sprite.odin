package luna_core

import "../base"

import "core:strings"
import stbi "vendor:stb/image"

sprite_t :: struct {
	data:                    [^]byte,
	width, height, channels: i32,
	path:                    string,
}

atlas_t :: struct {
	sprite: ^sprite_t,
	rects:  map[u32]base.iaabb,
}

atlas_init :: proc(sprite: ^sprite_t, sub_sprites: map[u32]base.iaabb) -> atlas_t {
	return {sprite, sub_sprites}
}

atlas_deinit :: proc(atlas: ^atlas_t) {
	clear_map(&atlas.rects)
	atlas.sprite = nil
}

sprite_from_png :: proc(path: string) -> sprite_t {
	sprite := sprite_t{}

	sprite.path = path
	sprite.data = stbi.load(
		strings.clone_to_cstring(path),
		&sprite.width,
		&sprite.height,
		&sprite.channels,
		0,
	)
	assert(sprite.data != nil, "failed to load sprite")
	return sprite
}

@(deprecated = "not implemented yet")
sprite_from_ase :: proc(path: string) -> sprite_t {
	sprite := sprite_t{}
	return sprite
}

sprite_deinit :: proc(sprite: ^sprite_t) {
	stbi.image_free(sprite.data)
}
