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
    return renderer
}

renderer_begin :: proc(pip: ^render_pipeline_t) {
	gl.ClearColor(pip.clear_color.r, pip.clear_color.g, pip.clear_color.b, pip.clear_color.a)
	gl.ClearDepth(0)
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
    
    gl.DrawArrays(gl.TRIANGLES, 0, 6)
}

renderer_deinit :: proc(renderer: ^renderer_t) {
	gl.DeleteVertexArrays(1, &renderer.vao)
}
