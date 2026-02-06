#version 430 core

in vec2 v_uv;
in vec4 v_tint;
flat in float v_texture_idx;
in vec2 v_world_pos;

layout(location = 0) out vec4 o_color;
layout(location = 1) out vec4 o_normal;
layout(location = 2) out vec4 o_position;

uniform sampler2D u_textures[16];
uniform sampler2D u_normal_textures[16];
uniform bool u_has_normal[16];

void main() {
    int tex_idx = int(v_texture_idx);

    vec4 tex_color = texture(u_textures[tex_idx], v_uv);
    o_color = tex_color * v_tint;

    if (u_has_normal[tex_idx]) {
        vec3 normal = texture(u_normal_textures[tex_idx], v_uv).rgb;
        normal = normal * 2.0 - 1.0;
        o_normal = vec4(normal, 1.0);
    } else {
        o_normal = vec4(0.0, 0.0, 1.0, 1.0);
    }

    o_position = vec4(v_world_pos, 0.0, 1.0);

    if (o_color.a <0.01) {
        discard;
    }
}