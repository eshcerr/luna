package luna_gfx

import "../base"

global_light_t :: struct {
	color: base.vec3,
}

point_light_t :: struct {
	color:     base.vec3,
	position:  base.ivec2,
	intensity: f32,
}

spot_light_t :: struct {
	color:                            base.vec3,
	position:                         base.ivec2,
	direction:                        base.vec2,
	intensity, cutoff, smooth_cutoff: f32,
}
