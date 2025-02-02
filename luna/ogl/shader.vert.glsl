#version 330 core

void main()
{
    vec2 vertices[6];

    vertices[0] = vec2(-0.5, 0.5);
    vertices[1] = vec2(-0.5, -0.5);
    vertices[2] = vec2(0.5, 0.5);
    vertices[3] = vec2(0.5, 0.5);
    vertices[4] = vec2(-0.5, -0.5);
    vertices[5] = vec2(0.5, -0.5);

    gl_Position = vec4(vertices[gl_VertexID], 1.0, 1.0);
}