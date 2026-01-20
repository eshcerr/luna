package luna_gfx

import "core:fmt"
import "../base"
import "../utils"
import "core:math"

import gl "vendor:OpenGL"

MAX_BATCH_ITEM :: 1024

batch_t :: struct {
	atlas:      ^atlas_t,
	texture_id: u32,
	batch_type: batch_type_e,
	items:      [dynamic]batch_item_t,
	materials:  [dynamic]material_t,
}

batch_item_t :: struct #packed {
	rect:            base.iaabb,
	position, size:  base.ivec2,
    scale:           base.vec2,
	rotation:        f32,
	material_id:     u32,
	options:         rendering_options_e,
}

batch_type_e :: enum {
	SPRITE,
	FONT,
}

rendering_options_e :: enum {
	NONE   = 0,
	FLIP_X = 0b001,
	FLIP_Y = 0b010,
}

batch_init :: proc(atlas: ^atlas_t, batch_type: batch_type_e) -> ^batch_t {
	batch:= new(batch_t)
	batch.atlas = atlas
	batch.items = make_dynamic_array([dynamic]batch_item_t)
	batch.materials = make_dynamic_array([dynamic]material_t)
	append_elem(&batch.materials, material_default)

	gl.GenTextures(1, &batch.texture_id)
	gl.BindTexture(gl.TEXTURE_2D, batch.texture_id)

	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

	internal_format: i32
	format: u32

	if batch_type == .SPRITE {
		internal_format = gl.SRGB8_ALPHA8
		format = gl.RGBA
	} else {
		internal_format = gl.R8
		format = gl.RED
	}

	gl.TexImage2D(
		gl.TEXTURE_2D,
		0,
		internal_format,
		i32(atlas.sprite.width),
		i32(atlas.sprite.height),
		0,
		format,
		gl.UNSIGNED_BYTE,
		&atlas.sprite.data[0],
	)

	return batch
}

batch_deinit :: proc(batch: ^batch_t) {
	clear_dynamic_array(&batch.items)
	delete_dynamic_array(batch.items)
	clear_dynamic_array(&batch.materials)
	delete_dynamic_array(batch.materials)
	gl.DeleteTextures(1, &batch.texture_id)
	free(batch)
}

batch_begin :: proc(batch: ^batch_t) {
	clear_dynamic_array(&batch.items)
	clear_dynamic_array(&batch.materials)
	append_elem(&batch.materials, material_default)
}

batch_get_or_create_material_id :: proc(batch: ^batch_t, material: ^material_t) -> u32 {
	if material == nil {return 0}
	index := utils.dynamic_array_find_element(&batch.materials, material^)
	if index == -1 {
		mat := material^
		mat.color.r = math.pow_f32(material.color.r, 2.2)
		mat.color.g = math.pow_f32(material.color.g, 2.2)
		mat.color.b = math.pow_f32(material.color.b, 2.2)
		mat.color.a = math.pow_f32(material.color.a, 2.2)

		new_index, err := append_elem(&batch.materials, mat)
		return u32(new_index)
	}
	return u32(index)
}

batch_add :: proc {
	batch_add_item,
	batch_add_from_atlas,
	batch_add_from_animation,
	batch_add_text,
}

batch_add_item :: proc(batch: ^batch_t, item: batch_item_t) {
	assert(len(batch.items) < MAX_BATCH_ITEM, "batch full")
	append_elem(&batch.items, item)
}

batch_add_from_atlas :: proc(
	batch: ^batch_t,
	atlas_item: u32,
	position, size: base.ivec2,
	scale: base.vec2 = {1, 1},
	rotation: f32 = 0.0,
	material: ^material_t = nil,
	options: rendering_options_e = .NONE,
) {
	assert(len(batch.items) < MAX_BATCH_ITEM, "batch full")
	rect, is_ok := batch.atlas.rects[atlas_item]
	assert(is_ok, "unregistered atlas item")

	append_elem(
		&batch.items,
		batch_item_t {
			rect = rect,
			position = position,
            size = size,
			scale = scale,
			rotation = math.to_radians_f32(rotation),
			material_id = batch_get_or_create_material_id(batch, material),
			options = options,
		},
	)
}

batch_add_from_animation :: proc(
	batch: ^batch_t,
	animation: ^animation_t,
	position, size: base.ivec2,
	scale: base.vec2 = {1, 1},
	rotation: f32 = 0.0,
	material: ^material_t = nil,
	options: rendering_options_e = .NONE,
) {
	batch_add_from_atlas(
		batch,
		animation_get_frame_rect(animation),
		position + animation_current_frame(animation).offset,
        size,
		scale,
		rotation,
		material,
		options,
	)
}


batch_add_text :: proc(
	batch: ^batch_t,
	text: string,
	font: ^font_t,
	position: base.ivec2,
	scale: base.vec2 = {1, 1},
	rotation: f32 = 0.0,
	material: ^material_t = nil,
	options: rendering_options_e = .NONE,
) {
	assert(len(batch.items) + len(text) < MAX_BATCH_ITEM, "batch full")

	local_position := position
	for character in text {
		if character == '\n' {
			local_position.x = position.x - i32(font_get_glyph_offset(font, ' ').x * scale.x)
			local_position.y += i32(f32(font.font_height) * scale.y)
			continue
		}

		if character < FONT_CHARACTER_BEGIN || character > FONT_CHARACTER_END {continue}

		char_rect, is_ok := batch.atlas.rects[u32(character - FONT_CHARACTER_BEGIN)]
		assert(is_ok, "unregistered atlas item")

		append_elem(
			&batch.items,
			batch_item_t {
				rect = char_rect,
				position = local_position + base.vec2_to_ivec2(font_get_glyph_offset(font, character) * scale),
				size = {char_rect.z, font.font_height},
                scale = scale,
				rotation = math.to_radians_f32(rotation),
				material_id = batch_get_or_create_material_id(batch, material),
				options = options,
			},
		)

		local_position.x += i32(f32(char_rect.z + 1) * scale.x)
	}
}
