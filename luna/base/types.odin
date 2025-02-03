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


mat4_orthographic_projection :: proc(left, right, top, bottom: f32) -> mat4 {
    m: mat4 = {}
    m[0][3] = -(right + left) / (right - left)
    m[1][3] = (top + bottom) / (top - bottom)
    m[2][3] = 0.0

    m[0][0] = 2.0 / (right - left)
    m[1][1] = 2.0 / (top - bottom)
    m[2][2] = 1.0 / (1.0 - 0.0)
    m[3][3] = 1.0

    return m
}
