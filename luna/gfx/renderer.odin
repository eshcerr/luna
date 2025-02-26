package luna_gfx

import "../base"

import "core:math"
import "core:strings"
import gl "vendor:OpenGL"

renderer_t :: struct {
	vao, transform_sbo, material_sbo:  u32,
	point_lights_sbo, spot_lights_sbo: u32,
	global_light:                      ^global_light_t,
	current_camera:                    ^camera_t,
	camera_proj:                       base.mat4,
	point_lights:                      [dynamic]point_light_t,
	spot_lights:                       [dynamic]spot_light_t,
}

renderer_init :: proc() -> ^renderer_t {
	renderer := new(renderer_t)
	gl.GenVertexArrays(1, &renderer.vao)
	gl.BindVertexArray(renderer.vao)

	gl.GenBuffers(1, &renderer.transform_sbo)
	gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 0, renderer.transform_sbo)
	gl.BufferData(
		gl.SHADER_STORAGE_BUFFER,
		size_of(batch_item_t) * MAX_BATCH_ITEM,
		nil,
		gl.DYNAMIC_DRAW,
	)

	gl.GenBuffers(1, &renderer.material_sbo)
	gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 1, renderer.material_sbo)
	gl.BufferData(
		gl.SHADER_STORAGE_BUFFER,
		size_of(material_t) * MAX_BATCH_ITEM,
		nil,
		gl.DYNAMIC_DRAW,
	)

	gl.GenBuffers(1, &renderer.point_lights_sbo)
	gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 1, renderer.point_lights_sbo)
	gl.BufferData(gl.SHADER_STORAGE_BUFFER, size_of(point_light_t) * 64, nil, gl.DYNAMIC_DRAW)

	gl.GenBuffers(1, &renderer.spot_lights_sbo)
	gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 1, renderer.spot_lights_sbo)
	gl.BufferData(gl.SHADER_STORAGE_BUFFER, size_of(spot_light_t) * 32, nil, gl.DYNAMIC_DRAW)

	gl.Enable(gl.DEPTH_TEST)
	gl.DepthFunc(gl.GREATER)

	gl.Enable(gl.FRAMEBUFFER_SRGB)
	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

	gl.ActiveTexture(gl.TEXTURE0) // only one texture at the time for now
	return renderer
}

renderer_deinit :: proc(renderer: ^renderer_t) {
	gl.DeleteVertexArrays(1, &renderer.vao)
	gl.DeleteBuffers(1, &renderer.transform_sbo)
	gl.DeleteBuffers(1, &renderer.material_sbo)
	free(renderer)
}

renderer_begin :: proc() {
	gl.ClearColor(pip.clear_color.r, pip.clear_color.g, pip.clear_color.b, pip.clear_color.a)
	gl.ClearDepth(0)
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
}

renderer_use_camera :: proc(renderer: ^renderer_t, camera: ^camera_t) {
	renderer.current_camera = camera
	renderer.camera_proj = camera_projection(renderer.current_camera)
}

renderer_use_shader :: proc(renderer: ^renderer_t, shader: ^shader_t) {
	gl.UseProgram(shader.program)
	gl.UniformMatrix4fv(
		gl.GetUniformLocation(
			shader.program,
			strings.clone_to_cstring(SHADER_ORTHOGRAPHIC_PROJ_UNIFORM),
		),
		1,
		false,
		&renderer.camera_proj[0][0],
	)

	// global light
	gl.Uniform3fv(
		gl.GetUniformLocation(shader.program, "global_light_color"),
		1,
		&renderer.global_light.color[0],
	)

	gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 1, renderer.point_lights_sbo)
	gl.BufferSubData(
		gl.SHADER_STORAGE_BUFFER,
		0,
		size_of(point_light_t) * len(renderer.point_lights),
		&raw_data(renderer.point_lights)[0],
	)
	gl.Uniform1i(
		gl.GetUniformLocation(shader.program, "point_light_count"),
		i32(len(renderer.point_lights)),
	)

	gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 2, renderer.spot_lights_sbo)
	gl.BufferSubData(
		gl.SHADER_STORAGE_BUFFER,
		0,
		size_of(spot_light_t) * len(renderer.spot_lights),
		&raw_data(renderer.spot_lights)[0],
	)
	gl.Uniform1i(
		gl.GetUniformLocation(shader.program, "spot_light_count"),
		i32(len(renderer.spot_lights)),
	)

}

renderer_draw_batch :: proc(renderer: ^renderer_t, batch: ^batch_t) {
	gl.BindTexture(gl.TEXTURE_2D, batch.texture_id)
	gl.ActiveTexture(gl.TEXTURE0) // only one texture at the time for now

	gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 0, renderer.transform_sbo)
	gl.BufferSubData(
		gl.SHADER_STORAGE_BUFFER,
		0,
		size_of(batch_item_t) * len(batch.items),
		&raw_data(batch.items)[0],
	)

	gl.DrawArraysInstanced(gl.TRIANGLES, 0, 6, i32(len(batch.items)))
}
