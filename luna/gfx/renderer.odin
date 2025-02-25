package luna_gfx

import "../base"

import "core:strings"
import gl "vendor:OpenGL"

renderer_t :: struct {
	vao, transform_sbo, material_sbo: u32,
	current_camera:                   ^camera_t,
	camera_proj:                      base.mat4,
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

    light:= point_light{color = {1, 0.3, 0.7}, position = {0, 0}, intensity = 10}
    glc:= base.vec3{0.5, 0.5, 0.5}
    gl.Uniform3fv(gl.GetUniformLocation(shader.program, "global_light_color"), 1, &glc[0])
    gl.Uniform3fv(gl.GetUniformLocation(shader.program, "light.color"), 1, &light.color[0])
    gl.Uniform2iv(gl.GetUniformLocation(shader.program, "light.position"), 1, &light.position[0])
    gl.Uniform1f(gl.GetUniformLocation(shader.program, "light.intensity"), light.intensity)
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

	gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 1, renderer.material_sbo)
	gl.BufferSubData(
		gl.SHADER_STORAGE_BUFFER,
		0,
		size_of(material_t) * len(batch.materials),
		&raw_data(batch.materials)[0],
	)

	gl.DrawArraysInstanced(gl.TRIANGLES, 0, 6, i32(len(batch.items)))
}
