package luna_gfx

import "../base"

import "core:strings"
import stbi "vendor:stb/image"

texture2D_wrap_option_e :: enum {
	CLAMP,
	CLAMP_TO_EDGE,
	REPEAT,
}

texture2D_filter_e :: enum {
	NEAREST,
	LINEAR,
}

texture2D_t :: struct {
	gpu_id:                  u32,
	width, height, channels: i32,
	wrap_options:            texture2D_wrap_option_e,
	filter:                  texture2D_filter_e,
	path:                    string,
	data:                    [^]byte,
}

atlas_t :: struct {
	texture: ^texture2D_t,
	rects:   []atlas_rect_t,
}

atlas_rect_t :: struct {
	rect:  base.iaabb,
	pivot: base.ivec2,
}

sprite_options_e :: enum {
	FLIP_X,
	FLIP_Y,
}

sprite_renderer_t :: struct {
	atlas:      ^atlas_t,
	atlas_rect: i32,
	material:   ^material_t,
	options:    bit_set[sprite_options_e;u8],
	layer:      i32,
}

blend_mode_e :: enum {
	OPAQUE,
	ALPHA_BLEND,
	ADDITIVE,
	MULTIPLY,
	PREMULTIPLIED,
}

material_property_t :: union {
	f32,
	base.vec2,
	base.vec3,
	base.vec4,
	^texture2D_t,
	i32,
}

material_t :: struct {
	shader:       ^shader_t,
	blend_mode:   blend_mode_e,
	properties:   map[string]material_property_t,
	main_texture: ^texture2D_t,
	tint:         base.vec4,
	render_queue: i32,
}





@(deprecated = "old gfx")
atlas_init :: proc(sprite: ^sprite_t, sub_sprites: map[u32]base.iaabb) -> ^atlas_t {
	atlas := new(atlas_t)
	atlas.sprite = sprite
	atlas.rects = sub_sprites
	return atlas
}

@(deprecated = "old gfx")
atlas_init_from_font :: proc(sprite: ^sprite_t, font: ^font_t, space_width: i32) -> ^atlas_t {
	atlas := new(atlas_t)
	atlas.sprite = sprite

	for i in 0 ..< (FONT_CHARACTER_END - FONT_CHARACTER_BEGIN) {
		atlas.rects[u32(i)] = font_get_glyph_rect(font, rune(i + FONT_CHARACTER_BEGIN))
	}

	atlas.rects[0] = {atlas.rects[0].x, atlas.rects[0].y, space_width, atlas.rects[0].w}

	return atlas
}

@(deprecated = "old gfx")
atlas_deinit :: proc(atlas: ^atlas_t) {
	clear_map(&atlas.rects)
	free(atlas)
}

@(deprecated = "old gfx")
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

@(deprecated = "old gfx")
sprite_deinit :: proc(sprite: ^sprite_t) {
	stbi.image_free(sprite.data)
	free(sprite)
}
