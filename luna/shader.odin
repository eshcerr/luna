package main

import "core:fmt"
import "core:os"
import "core:strings"

import gl "vendor:OpenGL"

shader_t :: struct {
	program: u32,
}

shader_init :: proc(vertexPath: string, fragmentPath: string) -> shader_t {
	vert := shader_compile(vertexPath, gl.VERTEX_SHADER)
	frag := shader_compile(vertexPath, gl.FRAGMENT_SHADER)

	defer gl.DeleteShader(vert)
	defer gl.DeleteShader(frag)

	program := gl.CreateProgram()

	gl.AttachShader(program, vert)
	gl.AttachShader(program, frag)
	gl.LinkProgram(program)

	link_success: i32
	gl.GetShaderiv(program, gl.LINK_STATUS, &(link_success))

	if (link_success == 0) {
		log: string
		gl.GetProgramInfoLog(program, 512, nil, raw_data(log))
		fmt.println("shader linking failed: {s}", log)
	}

	return shader_t{program}
}

shader_compile :: proc(path: string, type: u32) -> (shader: u32) {
	content, read_success := os.read_entire_file(path)
	if (!read_success) {
		fmt.println("error reading content of {s}", path)
		return 0
	}

	source := strings.unsafe_string_to_cstring(string(content))

	shader = gl.CreateShader(type)
	gl.ShaderSource(shader, 1, &source, nil)

	compile_success: i32
	gl.GetShaderiv(shader, gl.COMPILE_STATUS, &(compile_success))

	if (compile_success == 0) {
		log: string
		gl.GetShaderInfoLog(shader, 512, nil, raw_data(log))
		fmt.println("shader compilation failed: {s}", log)
		return 0
	}
	return
}

shader_use :: proc(shader: ^shader_t) {
	gl.UseProgram(shader.program)
}

shader_seti :: proc(shader: ^shader_t, name: string, v: i32) {
	gl.Uniform1i(gl.GetUniformLocation(shader.program, strings.clone_to_cstring(name)), v)
}

shader_setf :: proc(shader: ^shader_t, name: string, v: f32) {
	gl.Uniform1f(gl.GetUniformLocation(shader.program, strings.clone_to_cstring(name)), v)
}
