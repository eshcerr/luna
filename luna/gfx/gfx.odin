package luna_gfx

import "../base"
import luna_ecs "../core/ecs"
import "core:container/topological_sort"

import "core:strings"




@(deprecated = "old gfx - need to be reworked")
atlas_init_from_font :: proc(sprite: ^sprite_t, font: ^font_t, space_width: i32) -> ^atlas_t {
	atlas := new(atlas_t)
	atlas.sprite = sprite

	for i in 0 ..< (FONT_CHARACTER_END - FONT_CHARACTER_BEGIN) {
		atlas.rects[u32(i)] = font_get_glyph_rect(font, rune(i + FONT_CHARACTER_BEGIN))
	}

	atlas.rects[0] = {atlas.rects[0].x, atlas.rects[0].y, space_width, atlas.rects[0].w}

	return atlas
}


material_blend_mode_e :: enum {
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
	blend_mode:   material_blend_mode_e,
	properties:   map[string]material_property_t,
	main_texture: ^texture2D_t,
	render_queue: i32,
}