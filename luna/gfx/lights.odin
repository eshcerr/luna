package luna_gfx

import "../base"

global_light :: struct {
    color: base.vec3,
}

point_light :: struct {
    color: base.vec3,
    position: base.ivec2,
    intensity: f32,
}

spot_light :: struct {
    color: base.vec3,
    position: base.ivec2,
    direction: base.vec2,
    intensity, range: f32,
}


