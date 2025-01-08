package main

import gl "vendor:OpenGL"

vertex_t :: struct {
	pos: [3]f32,
}

renderer_t :: struct {
	vao, vbo, ebo: u32,
	shader:        shader_t,
}

shader_t :: struct {
	program, vert, frag: u32,
}

renderer_init :: proc(r: ^renderer_t) {
	vertices: [4]vertex_t = {
		{{0.5, 0.5, 0.0}},
		{{0.5, -0.5, 0.0}},
		{{-0.5, -0.5, 0.0}},
		{{-0.5, 0.5, 0.0}},
	}

	indices: [6]u32 = {0, 1, 3, 1, 2, 3}

	gl.GenVertexArrays(1, &r.vao)
	gl.BindVertexArray(r.vao)

	gl.GenBuffers(1, &r.vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, r.vbo)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.STATIC_DRAW)

	gl.GenBuffers(1, &r.ebo) 
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, r.ebo)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(indices), &indices, gl.STATIC_DRAW)

	gl.VertexAttribPointer(0, 3, gl.FLOAT, false, 3 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)

	vertexShaderSource: cstring = "#version 330 core\nlayout (location = 0) in vec3 aPos;\nvoid main()\n{\n   gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);\n}"
	fragmentShaderSource: cstring = "#version 330 core\nout vec4 FragColor;\nvoid main()\n{\n   FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0);\n}"

	r.shader = {}

	r.shader.vert = gl.CreateShader(gl.VERTEX_SHADER)
	gl.ShaderSource(r.shader.vert, 1, &vertexShaderSource, nil)
	gl.CompileShader(r.shader.vert)


	r.shader.frag = gl.CreateShader(gl.FRAGMENT_SHADER)
	gl.ShaderSource(r.shader.frag, 1, &fragmentShaderSource, nil)
	gl.CompileShader(r.shader.frag)

	r.shader.program = gl.CreateProgram()
	gl.AttachShader(r.shader.program, r.shader.vert)
	gl.AttachShader(r.shader.program, r.shader.frag)
	gl.LinkProgram(r.shader.program)

	gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)
}
renderer_draw :: proc(r: ^renderer_t) {
	gl.UseProgram(r.shader.program)

	gl.BindVertexArray(r.vao)
	gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)
}

renderer_deinit :: proc(r: ^renderer_t) {
	gl.DeleteShader(r.shader.vert)
	gl.DeleteShader(r.shader.frag)
}
