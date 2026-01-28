#version 400 core

in vec2 v_uv;
in vec4 v_tint;
in flat float v_texture_idx;

out vec4 FragColor;

uniform sampler2D u_textures[16];

void main() {
    vec4 tex_color = texture(u_textures[int(v_texture_idx)], v_uv);
    FragColor = tex_color * v_tint;
    
    if (FragColor.a < 0.01) {
        discard;
    }
}

/* USE IF WE CARE ABOUT POTATO CONFIGS (which we might want tbh)
#version 330 core

in vec2 v_uv;
in vec4 v_tint;
in flat float v_texture_idx;

out vec4 FragColor;

uniform sampler2D u_textures[16];

void main() {
    int tex_idx = int(v_texture_idx);
    
    // Sample texture based on index
    vec4 tex_color;
    switch(tex_idx) {
        case 0:  tex_color = texture(u_textures[0], v_uv); break;
        case 1:  tex_color = texture(u_textures[1], v_uv); break;
        case 2:  tex_color = texture(u_textures[2], v_uv); break;
        case 3:  tex_color = texture(u_textures[3], v_uv); break;
        case 4:  tex_color = texture(u_textures[4], v_uv); break;
        case 5:  tex_color = texture(u_textures[5], v_uv); break;
        case 6:  tex_color = texture(u_textures[6], v_uv); break;
        case 7:  tex_color = texture(u_textures[7], v_uv); break;
        case 8:  tex_color = texture(u_textures[8], v_uv); break;
        case 9:  tex_color = texture(u_textures[9], v_uv); break;
        case 10: tex_color = texture(u_textures[10], v_uv); break;
        case 11: tex_color = texture(u_textures[11], v_uv); break;
        case 12: tex_color = texture(u_textures[12], v_uv); break;
        case 13: tex_color = texture(u_textures[13], v_uv); break;
        case 14: tex_color = texture(u_textures[14], v_uv); break;
        case 15: tex_color = texture(u_textures[15], v_uv); break;
        default: tex_color = vec4(1.0, 0.0, 1.0, 1.0); break; // Magenta for error
    }
    
    FragColor = tex_color * v_tint;
    
    if (FragColor.a < 0.01) {
        discard;
    }
}
*/