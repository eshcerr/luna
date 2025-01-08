package main

import gl "vendor:OpenGL"

vertex_t :: struct {
	pos:   [3]f32,
	color: [3]f32,
	uv:    [2]f32,
}

renderer_t :: struct {
	vao, vbo, ebo: u32,
}

renderer_init :: proc() -> (r: renderer_t) {
	vertices: [4]vertex_t = {
		{{0.5, 0.5, 0.0}, {1.0, 1.0, 1.0}, {0.0, 0.0}},
		{{0.5, -0.5, 0.0}, {1.0, 1.0, 1.0}, {0.0, 1.0}},
		{{-0.5, -0.5, 0.0}, {1.0, 1.0, 1.0}, {1.0, 1.0}},
		{{-0.5, 0.5, 0.0}, {1.0, 1.0, 1.0}, {1.0, 0.0}},
	}

	indices: [6]u32 = {0, 1, 3, 1, 2, 3}

	r = {}

	gl.GenVertexArrays(1, &r.vao)
	gl.BindVertexArray(r.vao)

	gl.GenBuffers(1, &r.vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, r.vbo)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.STATIC_DRAW)

	gl.GenBuffers(1, &r.ebo)
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, r.ebo)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(indices), &indices, gl.STATIC_DRAW)

	gl.VertexAttribPointer(0, 3, gl.FLOAT, false, 8 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(1, 3, gl.FLOAT, false, 8 * size_of(f32), 3 * size_of(f32))
	gl.EnableVertexAttribArray(1)
	gl.VertexAttribPointer(2, 2, gl.FLOAT, false, 8 * size_of(f32), 6 * size_of(f32))
	gl.EnableVertexAttribArray(2)

	//gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)
	return 
}

renderer_draw :: proc(r: ^renderer_t, t: ^texture_t, s: ^shader_t) {
	shader_use(s)
	gl.BindTexture(gl.TEXTURE_2D, t.id)

	gl.BindVertexArray(r.vao)
	gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)
}

renderer_deinit :: proc(r: ^renderer_t) {
}
