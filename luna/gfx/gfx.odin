package luna_gfx

import "core:math"

// to future me, i made the decision to change my old rendering method to this one.
// this rendering method is based on the only two devlogs made by aarthificial on his pixel renderer.
// it will allow me to have post process shaders, smooth layers rendering for
// paralax layers and even top down layers, difered pixelated lights, upscaling and normal maps.


import "../base"
import "core:os"

import "base:runtime"
import "core:fmt"
import "core:reflect"
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

// this texture is binded to opengl through its id and if is initialized through an image in
// the init function store the image data as a byte array.
// note that this may change in the future for memory performance and texture will only be
// editable through render_texture_t
texture2D_t :: struct {
	// id of the texture on the gpu
	id:          u32,

	// color channels of the texture
	channels:    i32,

	// rect dimensions of the texture in pixels
	dimensions:  base.ivec2,

	// opengl wrap option
	wrap_option: texture2D_wrap_option_e,
	// opengl filter option
	filter:      texture2D_filter_e,

	// path to the image file
	path:        string,
	// pixels data to modify in cpu, may be dumped at init later if we don't need to modify at runtime
	// or it will need multiple functions to edit the texture pixels
	data:        [^]byte,
}

// initialize a texture from an image and opengl texture options
texture2D_init :: proc(
	path: string, // image path
	wrap_option: texture2D_wrap_option_e,
	filter: texture2D_filter_e,
) -> ^texture2D_t {
	texture := new(texture2D_t)
	texture.path = path
	texture.wrap_option = wrap_option
	texture.filter = filter

	// read pixels from the image into a byte array
	texture.data = stbi.load(
		strings.clone_to_cstring(path, context.temp_allocator),
		&texture.dimensions.x,
		&texture.dimensions.y,
		&texture.channels,
		0,
	)

	// bind to the gpu
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

	gl_filter: i32 = filter == .LINEAR ? gl.LINEAR : gl.NEAREST

	// set wrap and filter parameters
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl_wrap)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl_wrap)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl_filter)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl_filter)

	// create the texture on the gpu
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

// deinitialize a texture, free it from the GPU and RAM
texture2D_deinit :: proc(texture: ^texture2D_t) {
	gl.DeleteTextures(1, &texture.id)
	stbi.image_free(&texture.data[0])
	texture.data = nil
}

// represent rectangular areas on a texture.
// this is used to split sprites and render only given rectangles like for animations or sprite sheets.
atlas_t :: struct {
	texture: ^texture2D_t,
	rects:   map[u32]atlas_rect_t,
}

// represent a single rectangular area on a texture.
atlas_rect_t :: struct {
	rect:  base.iaabb,
	pivot: base.ivec2,
}

// init an atlas from a texture and it''s rects definition
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

// the shader_t struct stores the shader program id on the gpu and every uniforms fields in the shader code.
shader_t :: struct {
	// gpu program id
	program:  u32,

	// precalculated uniforms ids to avoid getting them at runtime
	uniforms: gl.Uniforms,
}

// initialize a shader from it's source files.
// this might cause issues for a only frag shader like for render textures ?
shader_init :: proc(vert_path, frag_path: string) -> ^shader_t {
	vert_data, vert_ok := os.read_entire_file(vert_path)
	if !vert_ok {
		fmt.eprintfln("Failed to read vertex shader: %s", vert_path)
		return nil
	}
	defer delete(vert_data)

	frag_data, frag_ok := os.read_entire_file(frag_path)
	if !frag_ok {
		fmt.eprintfln("Failed to read fragment shader: %s", frag_path)
		return nil
	}
	defer delete(frag_data)

	// Compiler vertex
	vert_shader := gl.CreateShader(gl.VERTEX_SHADER)
	vert_source := cstring(raw_data(vert_data))
	gl.ShaderSource(vert_shader, 1, &vert_source, nil)
	gl.CompileShader(vert_shader)

	success: i32
	gl.GetShaderiv(vert_shader, gl.COMPILE_STATUS, &success)
	if success == 0 {
		info_log: [1024]u8
		gl.GetShaderInfoLog(vert_shader, 1024, nil, raw_data(&info_log))
		fmt.eprintfln("VERTEX SHADER ERROR: %s\n%s", vert_path, cstring(raw_data(&info_log)))
		gl.DeleteShader(vert_shader)
		return nil
	}

	// Compiler fragment
	frag_shader := gl.CreateShader(gl.FRAGMENT_SHADER)
	frag_source := cstring(raw_data(frag_data))
	gl.ShaderSource(frag_shader, 1, &frag_source, nil)
	gl.CompileShader(frag_shader)

	gl.GetShaderiv(frag_shader, gl.COMPILE_STATUS, &success)
	if success == 0 {
		info_log: [1024]u8
		gl.GetShaderInfoLog(frag_shader, 1024, nil, raw_data(&info_log))
		fmt.eprintfln("FRAGMENT SHADER ERROR: %s\n%s", frag_path, cstring(raw_data(&info_log)))
		gl.DeleteShader(vert_shader)
		gl.DeleteShader(frag_shader)
		return nil
	}

	// Link program
	program := gl.CreateProgram()
	gl.AttachShader(program, vert_shader)
	gl.AttachShader(program, frag_shader)
	gl.LinkProgram(program)

	gl.GetProgramiv(program, gl.LINK_STATUS, &success)
	if success == 0 {
		info_log: [1024]u8
		gl.GetProgramInfoLog(program, 1024, nil, raw_data(&info_log))
		fmt.eprintfln(
			"SHADER LINKING ERROR: %s -> %s\n%s",
			vert_path,
			frag_path,
			cstring(raw_data(&info_log)),
		)
		gl.DeleteShader(vert_shader)
		gl.DeleteShader(frag_shader)
		gl.DeleteProgram(program)
		return nil
	}

	gl.DeleteShader(vert_shader)
	gl.DeleteShader(frag_shader)

	shader := new(shader_t)
	shader.program = program
	shader.uniforms = gl.get_uniforms_from_program(shader.program)

	return shader
}

// // set a shader uniform value
shader_set_uniform :: proc {// 	shader_set_uniform_i32,
	// 	shader_set_uniform_ivec2,
	// 	shader_set_uniform_ivec3,
	// 	shader_set_uniform_ivec4,
	// 	shader_set_uniform_f32,
	// 	shader_set_uniform_vec2,
	// 	shader_set_uniform_vec3,
	// 	shader_set_uniform_vec4,
	// 	shader_set_uniform_mat3,
	shader_set_uniform_mat4,
}

// shader_set_uniform_i32 :: proc(shader: ^shader_t, name: string, v: i32) {
// 	gl.Uniform1i(shader.uniforms[name].location, v)
// }
// shader_set_uniform_ivec2 :: proc(shader: ^shader_t, name: string, v: base.ivec2) {
// 	gl.Uniform2iv(shader.uniforms[name].location, 1, &v[0])
// }
// shader_set_uniform_ivec3 :: proc(shader: ^shader_t, name: string, v: base.ivec3) {
// 	gl.Uniform3iv(shader.uniforms[name].location, 1, &v[0])
// }
// shader_set_uniform_ivec4 :: proc(shader: ^shader_t, name: string, v: base.ivec4) {
// 	gl.Uniform4iv(shader.uniforms[name].location, 1, &v[0])
// }

// shader_set_uniform_f32 :: proc(shader: ^shader_t, name: string, v: f32) {
// 	gl.Uniform1f(shader.uniforms[name].location, v)
// }
// shader_set_uniform_vec2 :: proc(shader: ^shader_t, name: string, v: base.vec2) {
// 	gl.Uniform2fv(shader.uniforms[name].location, 1, &v[0])
// }
// shader_set_uniform_vec3 :: proc(shader: ^shader_t, name: string, v: base.vec3) {
// 	gl.Uniform3fv(shader.uniforms[name].location, 1, &v[0])
// }
// shader_set_uniform_vec4 :: proc(shader: ^shader_t, name: string, v: base.vec4) {
// 	gl.Uniform4fv(shader.uniforms[name].location, 1, &v[0])
// }

// shader_set_uniform_mat3 :: proc(shader: ^shader_t, name: string, v: base.mat3) {
// 	gl.UniformMatrix3fv(shader.uniforms[name].location, 1, false, &v[0][0])
// }
shader_set_uniform_mat4 :: proc(shader: ^shader_t, name: string, v: ^base.mat4) {
	gl.UniformMatrix4fv(shader.uniforms[name].location, 1, false, &v[0][0])
}

// the render_texture_t struct is used as a frame buffer on the gpu
// this is useful for post process effects or rendering passes
render_texture_t :: struct {
	fbo_id:     u32,
	texture_id: u32,
	dimensions: base.ivec2,
}

// initialize a render texture of given dimensions and bind it with a frame buffer on the gpu
render_texture_init :: proc(dimensions: base.ivec2) -> (render_texture_t, bool) {
	rt := render_texture_t {
		dimensions = dimensions,
	}

	// create the render texture frame buffer
	gl.GenFramebuffers(1, &rt.fbo_id)
	gl.BindFramebuffer(gl.FRAMEBUFFER, rt.fbo_id)

	// create the render texture texture
	gl.GenTextures(1, &rt.texture_id)
	gl.BindTexture(gl.TEXTURE_2D, rt.texture_id)
	gl.TexImage2D(
		gl.TEXTURE_2D,
		0,
		gl.RGBA8,
		rt.dimensions.x,
		rt.dimensions.y,
		0,
		gl.RGBA,
		gl.UNSIGNED_BYTE,
		nil,
	)

	// set parameters
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)

	// attach the framebuffer to the texture
	gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, rt.texture_id, 0)
	gl.DrawBuffer(gl.COLOR_ATTACHMENT0)

	// check if the initialisation went well
	status := gl.CheckFramebufferStatus(gl.FRAMEBUFFER)

	if status != gl.FRAMEBUFFER_COMPLETE {
		render_texture_deinit(&rt)
		gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
		return rt, false
	}

	gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
	return rt, true
}

// deinitialize a render texture from the gpu
render_texture_deinit :: proc(rt: ^render_texture_t) {
	if rt.fbo_id != 0 {
		gl.DeleteFramebuffers(1, &rt.fbo_id)
	}
	if rt.texture_id != 0 {
		gl.DeleteTextures(1, &rt.texture_id)
	}
}

// clear the render texture with a color
render_texture_clear :: proc(rt: ^render_texture_t, color := base.COLOR_TRANSPARENT) {
	gl.BindFramebuffer(gl.FRAMEBUFFER, rt.fbo_id)
	gl.Viewport(0, 0, rt.dimensions.x, rt.dimensions.y)
	gl.ClearColor(color.r, color.g, color.b, color.a)
	gl.Clear(gl.COLOR_BUFFER_BIT)
	gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
}

// sprite rendering options
sprite_options_e :: enum {
	FLIP_X,
	FLIP_Y,
}

// sprite renderer component
sprite_renderer_t :: struct {
	// sprite atlas data
	atlas:        ^atlas_t,
	atlas_rect:   u32,

	// sprite tint
	tint:         base.vec4,

	// rendering options flags
	options:      bit_set[sprite_options_e;u8],

	// display order layer, also act as depth
	layer:        i32,

	// normal map
	normal_atlas: ^atlas_t,
	normal_rect:  i32,
	has_normal:   bool,

	//shader
	shader:       ^shader_t,
}

// sprite instance data sent to the GPU to be draw on a frame buffer
sprite_instance_data_t :: struct #packed {
	position:    base.vec2,
	scale:       base.vec2,
	// precomputed sin and cos in radiants
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

// represent a single draw call data. it stores a maximum amount of textures for a single call
// and optimize the instance counts for given shaders.
// it's main use case is to cut down the number of draw calls to have faster rendering.
sprite_batch2D_draw_call_t :: struct {
	texture_slots:  [MAX_TEXTURE_PER_BATCH]^texture2D_t,
	texture_count:  int,
	instance_start: int,
	instance_count: int,
	shader:         ^shader_t,
}

sprite_batch2D_t :: struct {
	vao, vbo, ebo:           u32,
	quad_vbo:                u32,
	default_viewport:        base.ivec2,
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

component_count :: proc(ti: ^runtime.Type_Info) -> i32 {
	#partial switch v in ti.variant {
	case runtime.Type_Info_Float:
		return 1
	case runtime.Type_Info_Array:
		return i32(v.count)
	}
	return 1
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
	//if gl.BufferStorage != nil {
	//	batch.use_percistent_mapping = true
	//}

	gl.GenBuffers(1, &batch.vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, batch.vbo)

	gl.BufferData(
		gl.ARRAY_BUFFER,
		size_of(sprite_instance_data_t) * MAX_SPRITES_PER_BATCH,
		nil,
		gl.DYNAMIC_DRAW,
	)

	stride := size_of(sprite_instance_data_t)
	attrib_id := u32(1)

	ti := type_info_of(typeid_of(sprite_instance_data_t))
	b := runtime.type_info_base(ti)
	s := b.variant.(runtime.Type_Info_Struct)

	for i: i32 = 0; i < s.field_count; i += 1 {
		field_type := s.types[i]
		offset := s.offsets[i]
		components := component_count(field_type)
		gl.EnableVertexAttribArray(attrib_id)
		gl.VertexAttribPointer(attrib_id, i32(components), gl.FLOAT, gl.FALSE, i32(stride), offset)
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

sprite_batch2D_deinit :: proc(batch: ^sprite_batch2D_t) {
	//if batch.use_percistent_mapping {
	//	gl.BindBuffer(gl.ARRAY_BUFFER, batch.vbo)
	//	gl.UnmapBuffer(gl.ARRAY_BUFFER)
	//}

	gl.DeleteVertexArrays(1, &batch.vao)
	gl.DeleteBuffers(1, &batch.quad_vbo)
	gl.DeleteBuffers(1, &batch.vbo)
	gl.DeleteBuffers(1, &batch.ebo)

	delete(batch.draw_calls)
	delete(batch.texture_to_slot)
}

sprite_batch2D_begin :: proc(batch: ^sprite_batch2D_t) {
	batch.instance_count = 0
	clear(&batch.draw_calls)
	clear(&batch.texture_to_slot)
	batch.current_call = nil
}

sprite_batch2D_end :: proc(batch: ^sprite_batch2D_t) {
	if batch.instance_count == 0 do return

	if batch.current_call != nil {
		batch.current_call.instance_count =
			batch.instance_count - batch.current_call.instance_start
	}

	// if !batch.use_percistent_mapping {
	if batch.instance_count > 0 {
		gl.BindBuffer(gl.ARRAY_BUFFER, batch.vbo)

		gl.BufferData(
			gl.ARRAY_BUFFER,
			size_of(sprite_instance_data_t) * MAX_SPRITES_PER_BATCH,
			nil,
			gl.DYNAMIC_DRAW,
		)

		gl.BufferSubData(
			gl.ARRAY_BUFFER,
			0,
			batch.instance_count * size_of(sprite_instance_data_t),
			&batch.instances[batch.current_instance_buffer][0],
		)
	}
	// }

	gl.BindVertexArray(batch.vao)

	for &call in batch.draw_calls {
		if call.instance_count == 0 do continue

		shader_to_use := call.shader if call.shader != nil else batch.shader
		gl.UseProgram(shader_to_use.program)

		if sampler_loc, ok := batch.shader.uniforms["u_textures"]; ok {
			samplers: [MAX_TEXTURE_PER_BATCH]i32
			for i in 0 ..< MAX_TEXTURE_PER_BATCH {
				samplers[i] = i32(i)
			}
			gl.Uniform1iv(sampler_loc.location, MAX_TEXTURE_PER_BATCH, &samplers[0])
		}

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
			u32(call.instance_start),
		)
	}

	batch.current_instance_buffer = (batch.current_instance_buffer + 1) % 2
}

sprite_batch2D_begin_render_texture :: proc(batch: ^sprite_batch2D_t, rt: ^render_texture_t) {
	sprite_batch2D_begin(batch)
	gl.BindFramebuffer(gl.FRAMEBUFFER, rt.fbo_id)
	gl.Viewport(0, 0, rt.dimensions.x, rt.dimensions.y)
}

sprite_batch2D_end_render_texture :: proc(batch: ^sprite_batch2D_t) {
	sprite_batch2D_end(batch)
	gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
	gl.Viewport(0, 0, batch.default_viewport.x, batch.default_viewport.y)
}

sprite_batch2D_start_new_call :: proc(batch: ^sprite_batch2D_t, shader: ^shader_t) {
	call := sprite_batch2D_draw_call_t {
		instance_start = batch.instance_count,
		shader         = shader,
	}
	append(&batch.draw_calls, call)
	batch.current_call = &batch.draw_calls[len(batch.draw_calls) - 1]
	clear(&batch.texture_to_slot)
}

sprite_batch2D_get_texture_slot :: proc(
	batch: ^sprite_batch2D_t,
	texture: ^texture2D_t,
) -> (
	int,
	bool,
) {
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

	shader_to_use := sprite.shader if sprite.shader != nil else batch.shader

	needs_new_call := false
	if batch.current_call == nil {
		needs_new_call = true
	} else if batch.current_call.shader != shader_to_use {
		needs_new_call = true
	}

	if (needs_new_call) {
		if batch.current_call != nil {
			batch.current_call.instance_count =
				batch.instance_count - batch.current_call.instance_start
		}
		sprite_batch2D_start_new_call(batch, shader_to_use)
	}

	texture_slot, has_slot := sprite_batch2D_get_texture_slot(batch, sprite.atlas.texture)

	if !has_slot || batch.instance_count >= MAX_SPRITES_PER_BATCH {
		batch.current_call.instance_count =
			batch.instance_count - batch.current_call.instance_start

		sprite_batch2D_start_new_call(batch, shader_to_use)
		texture_slot, _ = sprite_batch2D_get_texture_slot(batch, sprite.atlas.texture)
	}

	if sprite.atlas_rect < 0 || sprite.atlas_rect >= u32(len(sprite.atlas.rects)) do return

	atlas_rect := sprite.atlas.rects[sprite.atlas_rect]
	inv_tex_width := 1.0 / f32(sprite.atlas.texture.dimensions.x)
	inv_tex_height := 1.0 / f32(sprite.atlas.texture.dimensions.y)

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
	final_scale := sprite_size * transform.scale * {1, -1}

	sin_r := math.sin(math.to_radians_f32(transform.rotation))
	cos_r := math.cos(math.to_radians_f32(transform.rotation))

	pivot := base.vec2{f32(atlas_rect.pivot.x), f32(atlas_rect.pivot.y)} - (sprite_size / 2)
	pivot_offset := pivot * transform.scale
	rotated_pivot := base.vec2 {
		pivot_offset.x * cos_r - pivot_offset.y * sin_r,
		pivot_offset.x * sin_r + pivot_offset.y * cos_r,
	}

	final_position := transform.position + (rotated_pivot / 2)

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


	// if batch.use_percistent_mapping {
	// 	batch.mapped_buffer[batch.instance_count] = instance
	// } else {
	batch.instances[batch.current_instance_buffer][batch.instance_count] = instance
	// }

	batch.instance_count += 1
}

sprite_batch2D_draw_render_texture :: proc {
	sprite_batch2D_draw_render_texture_rt,
	sprite_batch2D_draw_render_texture_tex,
}

sprite_batch2D_draw_render_texture_rt :: proc(
	batch: ^sprite_batch2D_t,
	rt: ^render_texture_t,
	position: base.vec2,
	size: base.vec2,
	rotation: f32 = 0.0,
	tint := base.vec4{1, 1, 1, 1},
	layer: i32 = 0,
) {
	temp_tex := texture2D_t {
		id         = rt.texture_id,
		dimensions = rt.dimensions,
	}
	sprite_batch2D_draw_render_texture_tex(batch, &temp_tex, position, size, rotation, tint, layer)
}

sprite_batch2D_draw_render_texture_tex :: proc(
	batch: ^sprite_batch2D_t,
	texture: ^texture2D_t,
	position: base.vec2,
	size: base.vec2,
	rotation: f32 = 0.0,
	tint := base.vec4{1, 1, 1, 1},
	layer: i32 = 0,
) {
	if batch.current_call == nil {
		sprite_batch2D_start_new_call(batch, batch.shader)
	}

	texture_slot, has_slot := batch.texture_to_slot[texture]

	if !has_slot {
		if batch.current_call.texture_count >= MAX_TEXTURE_PER_BATCH ||
		   batch.instance_count >= MAX_SPRITES_PER_BATCH {
			batch.current_call.instance_count =
				batch.instance_count - batch.current_call.instance_start

			sprite_batch2D_start_new_call(batch, batch.shader)
		}

		texture_slot = batch.current_call.texture_count
		batch.current_call.texture_slots[texture_slot] = texture
		batch.texture_to_slot[texture] = texture_slot
		batch.current_call.texture_count += 1
	}

	uv_min := base.vec2{0, 0}
	uv_max := base.vec2{1, 1}

	sin_r := math.sin(rotation)
	cos_r := math.cos(rotation)

	instance := sprite_instance_data_t {
		position    = position,
		scale       = size,
		sin_cos     = {sin_r, cos_r},
		layer       = f32(layer),
		texture_idx = f32(texture_slot),
		uv_min      = uv_min,
		uv_max      = uv_max,
		tint        = tint,
	}

	//if batch.use_percistent_mapping {
	//	batch.mapped_buffer[batch.instance_count] = instance
	//} else {
	batch.instances[batch.current_instance_buffer][batch.instance_count] = instance
	//}

	batch.instance_count += 1
}

light2D_t :: struct {
	position:             base.vec2,
	rotation:             f32,

	// color of the light
	tint:                 base.vec3,
	radius:               f32,
	direction:            base.vec2,

	// brightness of the light
	intensity:            f32,

	// volume of the light, act as if there was fog to  display the light on
	// this value is multiplied by the calculated light color and added to the output color
	volumetric_intensity: f32,

	// limit the light to a specific angle range
	inner_angle:          f32,
	outer_angle:          f32,

	// light layer
	layer:                i32,
}

gbuffer_t :: struct {
	color_rt:  render_texture_t,
	normal_rt: render_texture_t,
}

gbuffer_init :: proc(dimensions: base.ivec2) -> (gbuffer_t, bool) {
	gb := gbuffer_t{}

	ok: bool
	gb.color_rt, ok = render_texture_init(dimensions)
	if !ok do return gb, false

	gb.normal_rt, ok = render_texture_init(dimensions)
	if !ok {
		render_texture_deinit(&gb.color_rt)
		return gb, false
	}

	return gb, true
}

gbuffer_deinit :: proc(gb: ^gbuffer_t) {
	render_texture_deinit(&gb.color_rt)
	render_texture_deinit(&gb.normal_rt)
}

// deferred light renderer with multple render targets
deferred_light_renderer_t :: struct {
	batch:            ^sprite_batch2D_t,
	gbuffer:          gbuffer_t,

	// light accumulation texture
	light_rt:         render_texture_t,

	// fullscreen quad for composite pass
	fullscreen_quad:  fullscreen_quad_t,

	// shaders
	gbuffer_shader:   ^shader_t,
	light_shader:     ^shader_t,
	composite_shader: ^shader_t,

	// lights
	lights:           [dynamic]light2D_t,

	// other
	dimensions:       base.ivec2,
}

deferred_light_renderer_init :: proc(
	batch: ^sprite_batch2D_t,
	dimensions: base.ivec2,
) -> (
	deferred_light_renderer_t,
	bool,
) {
	renderer := deferred_light_renderer_t {
		batch      = batch,
		dimensions = dimensions,
		lights     = make([dynamic]light2D_t, 0, 128),
	}

	ok: bool
	renderer.gbuffer, ok = gbuffer_init(dimensions)
	if !ok do return renderer, false

	renderer.light_rt, ok = render_texture_init(dimensions)
	if !ok {
		gbuffer_deinit(&renderer.gbuffer)
		return renderer, false
	}

	renderer.fullscreen_quad = fullscreen_quad_init()

	return renderer, true
}

deferred_light_renderer_deinit :: proc(renderer: ^deferred_light_renderer_t) {
	gbuffer_deinit(&renderer.gbuffer)
	render_texture_deinit(&renderer.light_rt)
	fullscreen_quad_deinit(&renderer.fullscreen_quad)
	delete(renderer.lights)
}

deferred_light_renderer_add_light :: proc(renderer: ^deferred_light_renderer_t, light: light2D_t) {
	append(&renderer.lights, light)
}

deferred_light_renderer_clear_lights :: proc(renderer: ^deferred_light_renderer_t) {
	clear(&renderer.lights)
}

deferred_light_renderer_render_gbuffer :: proc(
	renderer: ^deferred_light_renderer_t,
	draw_cb: proc(batch: ^sprite_batch2D_t),
) {
	batch := renderer.batch

	gl.BindFramebuffer(gl.FRAMEBUFFER, renderer.gbuffer.color_rt.fbo_id)

	gl.FramebufferTexture2D(
		gl.FRAMEBUFFER,
		gl.COLOR_ATTACHMENT0,
		gl.TEXTURE_2D,
		renderer.gbuffer.color_rt.texture_id,
		0,
	)

	gl.FramebufferTexture2D(
		gl.FRAMEBUFFER,
		gl.COLOR_ATTACHMENT1,
		gl.TEXTURE_2D,
		renderer.gbuffer.normal_rt.texture_id,
		0,
	)

	draw_buffers := [?]u32{gl.COLOR_ATTACHMENT0, gl.COLOR_ATTACHMENT1}

	gl.DrawBuffers(len(draw_buffers), &draw_buffers[0])

	gl.Viewport(0, 0, renderer.dimensions.x, renderer.dimensions.y)
	gl.ClearColor(0, 0, 0, 0)
	gl.Clear(gl.COLOR_BUFFER_BIT)

	old_shader := batch.shader
	batch.shader = renderer.gbuffer_shader

	sprite_batch2D_begin(batch)
	draw_cb(batch)
	sprite_batch2D_end(batch)

	batch.shader = old_shader

	gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
}

deferred_light_renderer_render_light :: proc(
	renderer: ^deferred_light_renderer_t,
	light: ^light2D_t,
	first_light: bool,
) {
	batch := renderer.batch

	gl.BindFramebuffer(gl.FRAMEBUFFER, renderer.light_rt.fbo_id)
	gl.Viewport(0, 0, renderer.dimensions.x, renderer.dimensions.y)

	if first_light {
		gl.ClearColor(0, 0, 0, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)
	}

	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.ONE, gl.ONE)
	gl.BlendEquation(gl.FUNC_ADD)

	old_shader := batch.shader
	batch.shader = renderer.light_shader

	// Set light uniforms
	if info, ok := batch.shader.uniforms["u_light_pos"]; ok {
		gl.Uniform2f(info.location, light.position.x, light.position.y)
	}
	if info, ok := batch.shader.uniforms["u_light_color"]; ok {
		gl.Uniform3f(info.location, light.tint.r, light.tint.g, light.tint.b)
	}
	if info, ok := batch.shader.uniforms["u_light_intensity"]; ok {
		gl.Uniform1f(info.location, light.intensity)
	}
	if info, ok := batch.shader.uniforms["u_light_radius"]; ok {
		gl.Uniform1f(info.location, light.radius)
	}
	if info, ok := batch.shader.uniforms["u_volumetric_intensity"]; ok {
		gl.Uniform1f(info.location, light.volumetric_intensity)
	}
	if info, ok := batch.shader.uniforms["u_light_direction"]; ok {
		gl.Uniform2f(info.location, light.direction.x, light.direction.y)
	}
	if info, ok := batch.shader.uniforms["u_inner_angle"]; ok {
		gl.Uniform1f(info.location, light.inner_angle)
	}
	if info, ok := batch.shader.uniforms["u_outer_angle"]; ok {
		gl.Uniform1f(info.location, light.outer_angle)
	}

	// Bind G-Buffer textures
	if info, ok := batch.shader.uniforms["u_normal_tex"]; ok {
		gl.Uniform1i(info.location, 0)
	}
	if info, ok := batch.shader.uniforms["u_position_tex"]; ok {
		gl.Uniform1i(info.location, 1)
	}

	gl.ActiveTexture(gl.TEXTURE0)
	gl.BindTexture(gl.TEXTURE_2D, renderer.gbuffer.normal_rt.texture_id)

	sprite_batch2D_begin(batch)

	light_size := base.vec2{light.radius * 2, light.radius * 2}
	sprite_batch2D_draw_render_texture(
		batch,
		&renderer.gbuffer.color_rt,
		light.position,
		light_size,
		0,
		base.COLOR_WHITE,
		light.layer,
	)

	sprite_batch2D_end(batch)

	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

	gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
}

deferred_light_renderer_render_composite :: proc(renderer: ^deferred_light_renderer_t) {
	// Bind to the default framebuffer (screen)
	gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
	gl.Viewport(0, 0, renderer.dimensions.x, renderer.dimensions.y)

	// Use the composite shader
	gl.UseProgram(renderer.composite_shader.program)

	// Set texture uniforms
	if info, ok := renderer.composite_shader.uniforms["u_color_tex"]; ok {
		gl.Uniform1i(info.location, 0)
	}
	if info, ok := renderer.composite_shader.uniforms["u_light_tex"]; ok {
		gl.Uniform1i(info.location, 1)
	}

	// Bind the G-buffer color texture to texture unit 0
	gl.ActiveTexture(gl.TEXTURE0)
	gl.BindTexture(gl.TEXTURE_2D, renderer.gbuffer.color_rt.texture_id)

	// Bind the light accumulation texture to texture unit 1
	gl.ActiveTexture(gl.TEXTURE1)
	gl.BindTexture(gl.TEXTURE_2D, renderer.light_rt.texture_id)

	// Draw the fullscreen quad
	fullscreen_quad_draw(&renderer.fullscreen_quad, renderer.composite_shader)

	// Cleanup
	gl.BindTexture(gl.TEXTURE_2D, 0)
}

deferred_light_renderer_render_scene :: proc(
	renderer: ^deferred_light_renderer_t,
	draw_cb: proc(batch: ^sprite_batch2D_t),
) {
	deferred_light_renderer_render_gbuffer(renderer, draw_cb)

	for i in 0 ..< len(renderer.lights) {
		deferred_light_renderer_render_light(renderer, &renderer.lights[i], i > 0)
	}

	deferred_light_renderer_render_composite(renderer)
}

fullscreen_quad_t :: struct {
	vao, vbo: u32,
}


fullscreen_quad_init :: proc() -> fullscreen_quad_t {
	quad := fullscreen_quad_t{}

	// posx, posy, uvx, uvy
	vertices := [?]f32 {
		-1.0, -1.0, 0.0, 0.0,
		1.0, -1.0, 1.0, 0.0,
		1.0, 1.0, 1.0, 1.0,
		-1.0, 1.0, 0.0, 1.0,
	}

	gl.GenVertexArrays(1, &quad.vao)
	gl.GenBuffers(1, &quad.vbo)

	gl.BindVertexArray(quad.vao)
	gl.BindBuffer(gl.ARRAY_BUFFER, quad.vbo)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices[0], gl.STATIC_DRAW)

	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 4 * size_of(f32), 0)

	gl.EnableVertexAttribArray(1)
	gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 4 * size_of(f32), 2 * size_of(f32))

	gl.BindVertexArray(0)

	return quad
}

fullscreen_quad_deinit :: proc(quad: ^fullscreen_quad_t) {
	gl.DeleteVertexArrays(1, &quad.vao)
	gl.DeleteBuffers(1, &quad.vbo)
}

fullscreen_quad_draw :: proc(quad: ^fullscreen_quad_t, shader: ^shader_t) {
	gl.UseProgram(shader.program)
	gl.BindVertexArray(quad.vao)
	gl.DrawArrays(gl.TRIANGLE_FAN, 0, 4)
	gl.BindVertexArray(0)
}