package luna_gfx

import "../base"

import gl "vendor:OpenGL"

MAX_BATCH_ITEM :: 1024

batch_t :: struct {
	atlas:  ^atlas_t,
	tex_id: u32,
	items:  [dynamic]batch_item_t,
}

batch_item_t :: struct #packed {
	rect:            base.iaabb,
	position, scale: base.vec2,
	rotation:        f32,
	options:         rendering_options_e,
}

rendering_options_e :: enum {
	NONE   = 0,
	FLIP_X = 0b01,
	FLIP_Y = 0b10,
}

batch_init :: proc(atlas: ^atlas_t) -> batch_t {
	batch: batch_t = {}
	batch.atlas = atlas
	batch.items = make_dynamic_array([dynamic]batch_item_t)

	gl.GenTextures(1, &batch.tex_id)
	gl.BindTexture(gl.TEXTURE_2D, batch.tex_id)

	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

	gl.TexImage2D(
		gl.TEXTURE_2D,
		0,
		gl.SRGB8_ALPHA8,
		i32(atlas.sprite.width),
		i32(atlas.sprite.height),
		0,
		gl.RGBA,
		gl.UNSIGNED_BYTE,
		&atlas.sprite.data[0],
	)

	return batch
}

batch_deinit :: proc(batch: ^batch_t) {
	clear_dynamic_array(&batch.items)
	delete_dynamic_array(batch.items)
	gl.DeleteTextures(1, &batch.tex_id)
}

batch_begin :: proc(batch: ^batch_t) {
	clear_dynamic_array(&batch.items)
}

batch_add :: proc {
	batch_add_item,
	batch_add_from_atlas,
	batch_add_from_animation,
}

batch_add_item :: proc(batch: ^batch_t, item: batch_item_t) {
	assert(len(batch.items) < MAX_BATCH_ITEM, "batch full")
	append_elem(&batch.items, item)
}

batch_add_from_atlas :: proc(
	batch: ^batch_t,
	atlas_item: u32,
	position, scale: base.vec2,
	rotation: f32 = 0.0,
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
			scale = scale,
			rotation = rotation,
			options = options,
		},
	)
}

batch_add_from_animation :: proc(
	batch: ^batch_t,
	animation: ^animation_t,
	position, scale: base.vec2,
	rotation: f32 = 0.0,
	options: rendering_options_e = .NONE,
) {
	batch_add_from_atlas(
		batch,
		animation_get_frame_rect(animation),
		position,
		scale,
		rotation,
		options,
	)
}
