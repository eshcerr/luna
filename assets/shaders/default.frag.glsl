#version 430 core
  
layout (location = 0) in vec2 tex_coords;

layout (location = 0) out vec4 frag_color;

layout (location = 0) uniform sampler2D tex_atlas;

void main()
{
    vec4 tex_color = texelFetch(tex_atlas, ivec2(tex_coords), 0);
    if (tex_color.a == 0.0) { discard; }
    frag_color = tex_color;
}