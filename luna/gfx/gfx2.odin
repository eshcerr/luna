package luna_gfx

import "../base"

import "core:fmt"
import "core:strings"
import gl "vendor:OpenGL"
import stbi "vendor:stb/image"

// opengl texture wrap modes
texture2D_wrap_option_e :: enum {
	CLAMP,
	CLAMP_TO_EDGE,
	REPEAT,
}

// opengl texture filters
texture2D_filter_e :: enum {
	NEAREST,
	LINEAR,
}

// opengl texture
texture2D_t :: struct {
	// opengl texture id
	id:          u32,
	channels:    i32,
	dimensions:  base.ivec2,
	wrap_option: texture2D_wrap_option_e,
	filter:      texture2D_filter_e,
	// path to the image file
	path:        string,
	// pixels data to modify in cpu, may be dumped at init later if we don't need to modify at runtime
	// or it will need multiple functions to edit the texture pixels
	data:        [^]byte,
}

texture2D_init :: proc(
	path: string,
	wrap_option: texture2D_wrap_option_e,
	filter: texture2D_filter_e,
) -> ^texture2D_t {
	texture := new(texture2D_t)
	texture.path = path
	texture.wrap_option = wrap_option
	texture.filter = filter

	texture.data = stbi.load(
		strings.clone_to_cstring(path, context.temp_allocator),
		&texture.dimensions.x,
		&texture.dimensions.y,
		&texture.channels,
		0,
	)

	gl.GenTextures(1, &texture.id)
	gl.BindTexture(gl.TEXTURE_2D, texture.id)

	gl_wrap: i32
	switch wrap_option {
	case .CLAMP:
		gl_wrap = gl.CLAMP
	case .CLAMP_TO_EDGE:
		gl_wrap = gl.CLAMP_TO_EDGE
	case .REPEAT:
		gl_wrap = gl.REPEAT
	}

	gl_filter := filter ? gl.LINEAR : gl.NEAREST

	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl_wrap)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl_wrap)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl_filter)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl_filter)

	gl.TexImage2D(
		gl.TEXTURE_2D,
		0,
		gl.SRGB8_ALPHA8,
		i32(texture.dimensions.x),
		i32(texture.dimensions.y),
		0,
		gl.RGBA,
		gl.UNSIGNED_BYTE,
		&texture.data[0],
	)

	gl.GenerateMipmap(gl.TEXTURE_2D)
	return texture
}

texture_deinit :: proc(texture: ^texture2D_t) {
	gl.DeleteTextures(1, &texture.id)
	stbi.image_free(&texture.data[0])
	texture.data = nil
}

atlas_t :: struct {
	texture: ^texture2D_t,
	rects:   []atlas_rect_t,
}

atlas_rect_t :: struct {
	rect:  base.iaabb,
	pivot: base.ivec2,
}

// init an atlas from a texture and its rects definition
atlas_init :: proc(texture: ^texture2D_t, rects: map[u32]atlas_rect_t) -> ^atlas_t {
	atlas := new(atlas_t)
	atlas.texture = texture
	atlas.rects = rects
	return atlas
}

// deinit an atlas
atlas_deinit :: proc(atlas: ^atlas_t) {
	clear_map(&atlas.rects)
	free(atlas)
}

shader_t :: struct {
	program:  u32,
	// precalculated uniforms ids to avoid getting them at runtime
	uniforms: gl.Uniforms,
}

shader_init :: proc(vert_path, frag_path: string) -> ^shader_t {
	program, is_ok := gl.load_shaders_file(vert_path, frag_path)
	assert(is_ok, fmt.tprintf("shader failed to load:\nvert: %s\nfrag: %s", vert_path, frag_path))

	shader := new(shader_t)
	shader.program = program
	shader.uniforms = gl.get_uniforms_from_program(shader.program)

	return shader
}

shader_set_uniform :: proc {
	shader_set_uniform_i32,
	shader_set_uniform_ivec2,
	shader_set_uniform_ivec3,
	shader_set_uniform_ivec4,
	shader_set_uniform_f32,
	shader_set_uniform_vec2,
	shader_set_uniform_vec3,
	shader_set_uniform_vec4,
	shader_set_uniform_mat3,
	shader_set_uniform_mat4,
}

shader_set_uniform_i32 :: proc(shader: ^shader_t, name: string, v: i32) {
	gl.Uniform1i(shader.uniforms[name].location, v)
}
shader_set_uniform_ivec2 :: proc(shader: ^shader_t, name: string, v: base.ivec2) {
	gl.Uniform2iv(shader.uniforms[name].location, 1, &v[0])
}
shader_set_uniform_ivec3 :: proc(shader: ^shader_t, name: string, v: base.ivec3) {
	gl.Uniform3iv(shader.uniforms[name].location, 1, &v[0])
}
shader_set_uniform_ivec4 :: proc(shader: ^shader_t, name: string, v: base.ivec4) {
	gl.Uniform4iv(shader.uniforms[name].location, 1, &v[0])
}

shader_set_uniform_f32 :: proc(shader: ^shader_t, name: string, v: f32) {
	gl.Uniform1f(shader.uniforms[name].location, v)
}
shader_set_uniform_vec2 :: proc(shader: ^shader_t, name: string, v: base.vec2) {
	gl.Uniform2fv(shader.uniforms[name].location, 1, &v[0])
}
shader_set_uniform_vec3 :: proc(shader: ^shader_t, name: string, v: base.vec3) {
	gl.Uniform3fv(shader.uniforms[name].location, 1, &v[0])
}
shader_set_uniform_vec4 :: proc(shader: ^shader_t, name: string, v: base.vec4) {
	gl.Uniform4fv(shader.uniforms[name].location, 1, &v[0])
}

shader_set_uniform_mat3 :: proc(shader: ^shader_t, name: string, v: base.mat3) {
	gl.UniformMatrix3fv(shader.uniforms[name].location, 1, &v[0][0])
}
shader_set_uniform_mat4 :: proc(shader: ^shader_t, name: string, v: base.mat4) {
	gl.UniformMatrix4fv(shader.uniforms[name].location, 1, &v[0][0])
}

sprite_options_e :: enum {
	FLIP_X,
	FLIP_Y,
}

sprite_renderer_t :: struct {
	atlas:      ^atlas_t,
	atlas_rect: i32,
	tint:       base.vec4,
	//material:   ^material_t,
	options:    bit_set[sprite_options_e;u8],
	layer:      i32,
}

sprite_instance_data_t :: struct #packed {
	position:    base.vec2,
	scale:       base.vec2,
	sin_cos:     base.vec2,
	layer:       f32,
	texture_idx: f32,

	// UV
	uv_min:      base.vec2,
	uv_max:      base.vec2,

	// color
	tint:        base.vec4,
}

MAX_SPRITES_PER_BATCH :: 10000
MAX_TEXTURE_PER_BATCH :: 16
VERTICES_PER_SPRITE :: 4
INDICES_PER_SPRITE :: 6

sprite_batch2D_draw_call_t :: struct {
	texture_slots:  [MAX_TEXTURE_PER_BATCH]^texture2D_t,
	texture_count:  int,
	instance_start: int,
	instance_count: int,
}

sprite_batch2D_t :: struct {
	vao, vbo, ebo:           u32,
	quad_vbo:                u32,
	shader:                  ^shader_t,

	// batch data
	instances:               [2][MAX_SPRITES_PER_BATCH]sprite_instance_data_t,
	current_instance_buffer: int,
	instance_count:          int,

	// batching by texture
	draw_calls:              [dynamic]sprite_batch2D_draw_call_t,
	current_call:            ^sprite_batch2D_draw_call_t,

	// texture lookup for batching
	texture_to_slot:         map[^texture2D_t]int,

	// persistent mapped buffer (if ARB_buffer_storage available)
	use_percistent_mapping:  bool,
	mapped_buffer:           [^]sprite_instance_data_t,
}

sprite_batch2D_init :: proc(batch: ^sprite_batch2D_t, shader: ^shader_t) {
	batch.shader = shader
	batch.draw_calls = make([dynamic]sprite_batch2D_draw_call_t)
	batch.texture_to_slot = make(map[^texture2D_t]int)

	gl.GenVertexArrays(1, &batch.vao)
	gl.BindVertexArray(batch.vao)

	quad_vertices := [?]base.vec2{{-0.5, -0.5}, {0.5, -0.5}, {0.5, 0.5}, {-0.5, 0.5}}

	gl.GenBuffers(1, &batch.quad_vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, batch.quad_vbo)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(quad_vertices), &quad_vertices[0], gl.STATIC_DRAW)

	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, size_of(base.vec2), 0)
	gl.VertexAttribDivisor(0, 0)

	// try to use persistent mapping buffer
	batch.use_percistent_mapping = false
	if gl.BufferStorage != nil {
		batch.use_percistent_mapping = true
	}

	gl.GenBuffers(1, &batch.vbo)
	gl.BindBuffer(batch.vbo)

	if batch.use_percistent_mapping {
		flags := gl.MAP_WRITE_BIT | gl.MAP_PERSISTENT_BIT | gl.MAP_COHERENT_BIT
		gl.BufferStorage(
			gl.ARRAY_BUFFER,
			size_of(sprite_instance_data_t) * MAX_SPRITES_PER_BATCH,
			nil,
			u32(flags),
		)

		batch.mapped_buffer = cast([^]sprite_instance_data_t)gl.MapBufferRange(
			gl.ARRAY_BUFFER,
			0,
			size_of(sprite_instance_data_t) * MAX_SPRITES_PER_BATCH,
			u32(flags),
		)
	} else {
		gl.BufferData(
			gl.ARRAY_BUFFER,
			size_of(sprite_instance_data_t) * MAX_SPRITES_PER_BATCH,
			nil,
			gl.STREAM_DRAW,
		)
	}

	stride := size_of(sprite_instance_data_t)
	attrib_id := u32(1)

	ti := type_info_of(sprite_instance_data_t)
	si := ti.variant.(Type_Info_Struct)
	for i: i32 = 0; i < si.field_count; i += 1 {
		field_type := si.types[i]
		offset := si.offsets[i]

		gl.EnableVertexAttribArray(attrib_id)
		gl.VertexAttribPointer(
			attrib_id,
			field_type.size,
			gl.FLOAT,
			gl.FALSE,
			stride,
			rawptr(offset),
		)
		gl.VertexAttribDivisor(attrib_id, 1)
		attrib_id += 1
	}

	// ebo
	indices := [?]u32{0, 1, 2, 2, 3, 0}
	gl.GenBuffers(1, &batch.ebo)
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, batch.ebo)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(indices), &indices[0], gl.STATIC_DRAW)

	gl.BindVertexArray(0)
}

sprite_batch2D_begin :: proc(batch: ^sprite_batch2D_t) {
	batch.instance_count = 0
	clear(&batch.draw_calls)
	clear(&batch.texture_to_slot)
	batch.current_call = nil
}

sprite_batch2D_start_new_call :: proc(batch: ^sprite_batch2D_t) {
	call := sprite_batch2D_draw_call_t {
		instance_start = batch.instance_count,
	}
	append(&batch.draw_calls, call)
	batch.current_call = &batch.draw_calls[len(batch.draw_calls) - 1]
	clear(&batch.texture_to_slot)
}

sprite_batch2D_get_texture_slot :: proc(batch: ^sprite_batch2D_t, texture: ^texture_t) {
	if slot, ok := batch.texture_to_slot[texture]; ok {
		return slot, true
	}

	if batch.current_call.texture_count < MAX_TEXTURE_PER_BATCH {
		slot := batch.current_call.texture_count
		batch.current_call.texture_slots[slot] = texture
		batch.texture_to_slot[texture] = slot
		batch.current_call.texture_count += 1
		return slot, true
	}

	return -1, false
}

sprite_batch2D_draw :: proc(
	batch: ^sprite_batch2D_t,
	sprite: ^sprite_renderer_t,
	transform: ^base.transform2D_t,
) {
	if sprite.atlas == nil do return

	if batch.current_call == nil {
		sprite_batch2D_start_new_call(batch)
	}

	texture_slot, has_slot := sprite_batch2D_get_texture_slot(batch, sprite.atlas.texture)

	if !has_slot || batch.instance_count >= MAX_SPRITES_PER_BATCH {
		batch.current_call.instance_count =
			batch.instance_count - batch.current_call.instance_start

		sprite_batch2D_start_new_call(batch)
		texture_slot, _ = sprite_batch2D_get_texture_slot(batch, sprite.atlas.texture)
	}

	if sprite.atlas_rect < 0 || sprite.atlas_rect >= i32(len(sprite.atlas.rects)) do return

	atlas_rect := sprite.atlas.rects[sprite.atlas_rect]
	inv_tex_width := 1.0 / f32(sprite.atlas.texture.dimensions.x)
	inv_tex_width := 1.0 / f32(sprite.atlas.texture.dimensions.y)

	uv_min := base.vec2 {
		f32(atlas_rect.rect.x) * inv_tex_width,
		f32(atlas_rect.rect.y) * inv_tex_height,
	}
	uv_max := base.vec2 {
		f32(atlas_rect.rect.x + atlas_rect.rect.z) * inv_tex_width,
		f32(atlas_rect.rect.y + atlas_rect.rect.w) * inv_tex_height,
	}

	if .FLIP_X in sprite.options {
		uv_min.x, uv_max.x = uv_max.x, uv_min.x
	}
	if .FLIP_Y in sprite.options {
		uv_min.y, uv_max.y = uv_max.y, uv_min.y
	}

	sprite_size := base.vec2{f32(atlas_rect.rect.z), f32(atlas_rect.rect.w)}
	final_scale := sprite_size * transform.scale

	sin_r := math.sin(transform.rotation)
	cos_r := math.cos(transform.rotation)

	pivot := base.vec2{f32(atlas_rect.pivot.x), f32(atlas_rect.pivot.y)}
	pivot_offset := pivot * transform.scale
	rotated_pivot := base.vec2 {
		pivot_offset.x * cos_r - pivot_offset.y * sin_r,
		pivot_offset.x * sin_r + pivot_offset.y * cos_r,
	}

	final_position := transform.position - rotated_pivot

	instance := sprite_instance_data_t {
		position    = final_position,
		scale       = final_scale,
		sin_cos     = {sin_r, cos_r},
		layer       = f32(sprite.layer),
		texture_idx = f32(texture_slot),
		uv_min      = uv_min,
		uv_max      = uv_max,
		tint        = sprite.tint,
	}

	if batch.use_percistent_mapping {
		batch.mapped_buffer[batch.instance_count] = instance
	} else {
		batch.instances[batch.current_instance_buffer][batch.instance_count] = instance
	}

	batch.instance_count += 1
}

sprite_batch2D_end :: proc(batch: ^sprite_batch2D_t) {
	if batch.instance_count == 0 do return

	if batch.current_call != nil {
		batch.current_call.instance_count =
			batch.instance_count - batch.current_call.instance_start
	}

	if !batch.use_percistent_mapping {
		gl.BindBuffer(gl.ARRAY_BUFFER, batch.vbo)

		gl.BufferData(
			gl.ARRAY_BUFFER,
			size_of(sprite_instance_data_t) * MAX_SPRITES_PER_BATCH,
			nil,
			gl.STREAM_DRAW,
		)

		gl.BufferSubData(
			gl.ARRAY_BUFFER,
			0,
			batch.instance_count * size_of(sprite_instance_data_t),
			&batch.instances[batch.current_instance_buffer][0],
		)
	}

	gl.UseProgram(shader.program)
	gl.BindVertexArray(batch.vao)

	if sampler_loc, ok := batch.shader.uniforms["u_textures"]; ok {
		samplers: [MAX_TEXTURE_PER_BATCH]i32
		for i in 0 ..< MAX_TEXTURE_PER_BATCH {
			samplers[i] = i32(i)
		}
		gl.Uniform1iv(sampler_loc, MAX_TEXTURE_PER_BATCH, &sampler[0])
	}

	for &call in batch.draw_calls {
		if call.instance_count == 0 do continue

		for i in 0 ..< call.texture_count {
			gl.ActiveTexture(gl.TEXTURE0 + u32(i))
			gl.BindTexture(gl.TEXTURE_2D, call.texture_slots[i].id)
		}

		gl.DrawElementsInstancedBaseInstance(
			gl.TRIANGLES,
			6,
			gl.UNSIGNED_INT,
			nil,
			i32(call.instance_count),
			i32(call.instance_start),
		)
	}

	batch.current_instance_buffer = (batch.current_instance_buffer + 1) % 2
}

sprite_batch2D_deinit :: proc(batch: ^sprite_batch2D_t) {
	if batch.use_percistent_mapping {
		gl.BindBuffer(gl.ARRAY_BUFFER, batch.vbo)
		gl.UnmapBuffer(gl.ARRAY_BUFFER)
	}

	gl.DeleteVertexArrays(1, &batch.vao)
	gl.DeleteBuffers(1, &batch.quad_vbo)
	gl.DeleteBuffers(1, &batch.vbo)
	gl.DeleteBuffers(1, &batch.ebo)

	delete(batch.draw_calls)
	delete(batch.texture_to_slot)
}
