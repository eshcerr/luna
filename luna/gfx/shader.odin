package luna_gfx

import "core:fmt"
import "core:os"
import "core:strings"

import gl "vendor:OpenGL"

shader_t :: struct {
	program: u32,
}

shader_init :: proc(vert, frag: string) -> (s: shader_t = {}) {
	program, is_ok := gl.load_shaders_file(vert, frag)
	assert(is_ok, "shader loading failed")
	s.program = program
	return 
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
