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
	frag := shader_compile(fragmentPath, gl.FRAGMENT_SHADER)

	defer gl.DeleteShader(vert)
	defer gl.DeleteShader(frag)

	program := gl.CreateProgram()

	gl.AttachShader(program, vert)
	gl.AttachShader(program, frag)
	gl.LinkProgram(program)

	link_success: i32
	gl.GetProgramiv(program, gl.LINK_STATUS, &(link_success))

	if (link_success == 0) {
		info_length: i32
		gl.GetProgramiv(program, gl.INFO_LOG_LENGTH, &(info_length))

		info_log := make([]u8, info_length)
		defer delete(info_log)

		gl.GetProgramInfoLog(program, info_length, nil, &info_log[0])

		fmt.println("program link failed ", info_log)
	}

	return shader_t{program}
}

shader_compile :: proc(path: string, type: u32) -> (shader: u32) {
	content, read_success := os.read_entire_file(path)
	if (read_success == false) {
		fmt.println("error reading content of ", path)
		return 0
	}

	source := cstring(raw_data(content))

	shader = gl.CreateShader(type)
	gl.ShaderSource(shader, 1, &source, nil)
    gl.CompileShader(shader)

	status: i32
	gl.GetShaderiv(shader, gl.COMPILE_STATUS, &(status))

	if status != 0 do return

	info_length: i32
	gl.GetShaderiv(shader, gl.INFO_LOG_LENGTH, &(info_length))
	fmt.println(info_length)
    
	info_log := make([]u8, info_length)
	defer delete(info_log)

	gl.GetShaderInfoLog(shader, info_length, nil, &info_log[0])

	fmt.println("shader compilation failed ", info_log)
	return 0
}

shader_deinit :: proc(shader: ^shader_t) {
	gl.DeleteProgram(shader.program)
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
