package luna_base

import "core:math/linalg"

vec2 :: [2]f32
vec3 :: [3]f32
vec4 :: [4]f32

ivec2 :: [2]i32
ivec3 :: [3]i32
ivec4 :: [4]i32

mat3 :: linalg.Matrix3x3f32
mat4 :: linalg.Matrix4x4f32

aabb :: [4]f32
iaabb :: [4]i32

circle :: struct {
	center: vec2,
	radius:   f32,
}

polygon :: struct {
	points: []vec2,
}

vec2_to_ivec2 :: proc(v: vec2) -> ivec2 {
	return ivec2{i32(v.x), i32(v.y)}
}

ivec2_to_vec2 :: proc(v: ivec2) -> vec2 {
	return vec2{f32(v.x), f32(v.y)}
}
