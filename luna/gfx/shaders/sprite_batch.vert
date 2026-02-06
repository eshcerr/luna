#version 430 core

layout(location = 0) in vec2 a_vertex_pos;
layout(location = 1) in vec2 a_position;
layout(location = 2) in vec2 a_scale;
layout(location = 3) in vec2 a_sin_cos;
layout(location = 4) in float a_layer;
layout(location = 5) in float a_texture_idx;
layout(location = 6) in vec2 a_uv_min;
layout(location = 7) in vec2 a_uv_max;
layout(location = 8) in vec4 a_tint;

out vec2 v_uv;
out vec4 v_tint;
flat out float v_texture_idx;
out vec2 v_world_pos;

uniform mat4 u_projection;

void main() {
    vec2 scaled_pos = a_vertex_pos * a_scale;
    vec2 rotated_pos = vec2(
        scaled_pos.x * a_sin_cos.y - scaled_pos.y * a_sin_cos.x,
        scaled_pos.x * a_sin_cos.x + scaled_pos.y * a_sin_cos.y
    );
    vec2 world_pos = rotated_pos + a_position;

    gl_Position = u_projection * vec4(world_pos, a_layer, 1.0);

    v_uv = mix(a_uv_min, a_uv_max, a_vertex_pos + 0.5);
    v_tint = a_tint;
    v_texture_idx = a_texture_idx;
    v_world_pos = world_pos;
}