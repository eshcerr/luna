package luna_gfx

import "../base"

import gl "vendor:OpenGL"

renderer_t :: struct {
	vao: u32,
}

renderer_init :: proc() -> renderer_t {
	renderer := renderer_t{}
	gl.GenVertexArrays(1, &renderer.vao)
	gl.BindVertexArray(renderer.vao)

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

	gl.DrawArrays(gl.TRIANGLES, 0, 6)
}

renderer_draw :: proc(renderer: ^renderer_t, texture: ^texture_t) {
	gl.BindTexture(gl.TEXTURE_2D, texture.id)
}
