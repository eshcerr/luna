package luna_gfx

import "../base"

light_type_e :: enum {
	GLOBAL,
	POINT,
	SPOT,
}

global_light_t :: struct {
	color: base.vec3,
}

point_light_t :: struct {
	color:                                  base.vec3,
	position:                               base.ivec2,
	intensity, constant, linear, quadratic: f32,
}

spot_light_t :: struct {
	color:                                  base.vec3,
	position:                               base.ivec2,
	direction:                              base.vec2,
	intensity, constant, linear, quadratic: f32,
	cutoff, smooth_cutoff:                  f32,
}
