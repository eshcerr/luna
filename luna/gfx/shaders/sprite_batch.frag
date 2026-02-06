#version 430 core

in vec2 v_uv;
in vec4 v_tint;
in flat float v_texture_idx;

out vec4 FragColor;

uniform sampler2D u_textures[16];

void main() {
    int tex_idx = int(v_texture_idx);
    
    vec4 tex_color = texture(u_textures[tex_idx], v_uv);
    FragColor = tex_color * v_tint;
    
    if (FragColor.a < 0.01) {
        discard;
    }
}