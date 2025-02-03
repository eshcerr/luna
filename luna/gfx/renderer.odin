package luna_gfx

import "../base"

import "core:strings"
import gl "vendor:OpenGL"

renderer_t :: struct {
	vao, sbo: u32,
}

renderer_init :: proc() -> renderer_t {
	renderer := renderer_t{}
	gl.GenVertexArrays(1, &renderer.vao)
	gl.BindVertexArray(renderer.vao)

	gl.GenBuffers(1, &renderer.sbo)
	gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 0, renderer.sbo)
	gl.BufferData(
		gl.SHADER_STORAGE_BUFFER,
		size_of(batch_item_t) * MAX_BATCH_ITEM,
		nil,
		gl.DYNAMIC_DRAW,
	)

	gl.Enable(gl.DEPTH_TEST)
	gl.DepthFunc(gl.GREATER)

	gl.Enable(gl.FRAMEBUFFER_SRGB)

	gl.ActiveTexture(gl.TEXTURE0) // only one texture at the time for now
	return renderer
}

renderer_deinit :: proc(renderer: ^renderer_t) {
	gl.DeleteVertexArrays(1, &renderer.vao)
}

renderer_begin :: proc(pip: ^render_pipeline_t) {
	gl.ClearColor(pip.clear_color.r, pip.clear_color.g, pip.clear_color.b, pip.clear_color.a)
	gl.ClearDepth(0)
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
}

renderer_update_camera :: proc(camera: ^camera_t) {
	shader: i32
	gl.GetIntegerv(gl.CURRENT_PROGRAM, &shader)
	game_camera_proj := camera_projection(camera)

	gl.UniformMatrix4fv(
		gl.GetUniformLocation(u32(shader), strings.clone_to_cstring("orthographic_projection")),
		1,
		false,
		&game_camera_proj[0][0],
	)
}

renderer_draw_batch :: proc(batch: ^batch_t) {
	gl.BindTexture(gl.TEXTURE_2D, batch.tex_id)
	gl.ActiveTexture(gl.TEXTURE0) // only one texture at the time for now

	gl.BufferSubData(
		gl.SHADER_STORAGE_BUFFER,
		0,
		size_of(batch_item_t) * len(batch.items),
		&raw_data(batch.items)[0],
	)

	gl.DrawArraysInstanced(gl.TRIANGLES, 0, 6, i32(len(batch.items)))
}
