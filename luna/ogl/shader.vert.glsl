#version 430 core

layout (location = 0) out vec2 tex_coords;

void main()
{
    vec2 vertices[6];

    vertices[0] = vec2(-0.5, 0.5);
    vertices[1] = vec2(-0.5, -0.5);
    vertices[2] = vec2(0.5, 0.5);
    vertices[3] = vec2(0.5, 0.5);
    vertices[4] = vec2(-0.5, -0.5);
    vertices[5] = vec2(0.5, -0.5);

    float left = 0.0;
    float top = 0.0;
    float right = 1078.0;
    float bottom = 1080.0;

    vec2 tex_coords_array[6] = {
        vec2(left, top),
        vec2(left, bottom),
        vec2(right, top),
        vec2(right, top),
        vec2(left, bottom),
        vec2(right, bottom)
    };

    gl_Position = vec4(vertices[gl_VertexID], 1.0, 1.0);
    tex_coords = tex_coords_array[gl_VertexID];
}