package luna_gfx

import "../base"

import "core:slice"
import "core:mem"

vertex_t :: struct #packed {
	position: base.vec3,
	uv:       base.vec2,
	normal:   base.vec3,
	color:    base.vec4,
}

mesh_t :: struct {
	vertices: []vertex_t,
	indices:  []u32,
}

mesh_clone :: proc(mesh: ^mesh_t) -> mesh_t {
	return {vertices = slice.clone(mesh.vertices), indices = slice.clone(mesh.indices)}
}




