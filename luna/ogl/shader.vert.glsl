#version 430 core

struct batch_item_t {
    ivec4 rect;
    vec2 position;
    vec2 scale;
};

layout (std430, binding = 0) buffer batch_sbo {
    batch_item_t items[];
};

uniform mat4 orthographic_projection;

layout (location = 0) out vec2 tex_coords;

void main()
{
    batch_item_t item = items[gl_InstanceID];

    vec2 vertices[6] = {
        item.position,
        vec2(item.position + vec2(0.0, item.rect.w * item.scale.y)),
        vec2(item.position + vec2(item.rect.z * item.scale.x, 0.0)),
        vec2(item.position + vec2(item.rect.z * item.scale.x, 0.0)),
        vec2(item.position + vec2(0.0, item.rect.w * item.scale.y)),
        item.position + item.rect.zw * item.scale
    };

    float left = item.rect.x;
    float top = item.rect.y;
    float right = item.rect.x + item.rect.z;
    float bottom = item.rect.y + item.rect.w;

    vec2 tex_coords_array[6] = {
        vec2(left, top),
        vec2(left, bottom),
        vec2(right, top),
        vec2(right, top),
        vec2(left, bottom),
        vec2(right, bottom)
    };

    vec2 vertex_pos = vertices[gl_VertexID];
    gl_Position = orthographic_projection * vec4(vertex_pos, 0.0, 1.0);

    tex_coords = tex_coords_array[gl_VertexID];
}