package luna_gfx

import "../base"

material_t :: struct {
    ambient: base.vec3,
    diffuse: base.vec3,
    specular: base.vec3,
    shininess: f32,
}