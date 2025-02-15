package luna_gfx

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

atlas_init :: proc(sprite: ^sprite_t, sub_sprites: map[u32]base.iaabb) -> ^atlas_t {
	atlas:= new(atlas_t)
	atlas.sprite = sprite
	atlas.rects = sub_sprites
	return atlas
}

atlas_init_from_font :: proc(sprite: ^sprite_t, font: ^font_t, space_width: i32) -> ^atlas_t {
	atlas:= new(atlas_t)
	atlas.sprite = sprite

	for i in 0 ..< (FONT_CHARACTER_END - FONT_CHARACTER_BEGIN) {
		atlas.rects[u32(i)] = font_get_glyph_rect(font, rune(i + FONT_CHARACTER_BEGIN))
	}

	atlas.rects[0] = {atlas.rects[0].x, atlas.rects[0].y, space_width, atlas.rects[0].w}

	return atlas
}

atlas_deinit :: proc(atlas: ^atlas_t) {
	clear_map(&atlas.rects)
	free(atlas)
}

sprite_from_png :: proc(path: string) -> ^sprite_t {
	sprite := new(sprite_t)

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
sprite_from_ase :: proc(path: string) -> ^sprite_t {
	sprite := new(sprite_t)
	return sprite
}

sprite_deinit :: proc(sprite: ^sprite_t) {
	stbi.image_free(sprite.data)
	free(sprite)
}
