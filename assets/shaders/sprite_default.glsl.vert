#version 430 core

struct batch_item_t {
    ivec4 rect;
    ivec2 position;
    ivec2 size;
    vec2 scale;
    float rotation;
	uint material_id;
    uint options;
};

layout (std430, binding = 0) buffer batch_sbo {
    batch_item_t items[];
};

uniform mat4 orthographic_projection;

layout (location = 0) out vec2 uv;
layout (location = 1) out flat uint material_id;
layout (location = 2) out vec2 world_position;

uint OPTIONS_FLIP_X = 1 << 0;
uint OPTIONS_FLIP_Y = 1 << 1;

void main()
{
    batch_item_t item = items[gl_InstanceID];
	
    vec2 vertices[6] = {
        item.position,
        vec2(item.position - vec2(0.0, int(item.size.y * item.scale.y))),
        vec2(item.position + vec2(int(item.size.x * item.scale.x), 0.0)),
        vec2(item.position + vec2(int(item.size.x * item.scale.x), 0.0)),
        vec2(item.position - vec2(0.0, int(item.size.y * item.scale.y))),
        item.position + ivec2(item.size.x * item.scale.x, -(item.size.y * item.scale.y))
	};

	if (item.rotation != 0.0f) {
		mat2 rotation;
		rotation[0] = vec2(cos(item.rotation), -sin(item.rotation));
		rotation[1] = vec2(sin(item.rotation), cos(item.rotation));
		
		vec2 center = item.position + ivec2(item.size.x * item.scale.x, item.size.y * item.scale.y) / 2;
		
		for (int i = 0; i <= 6; i++) {
			vertices[i] = vertices[i] - center;
			vertices[i] = vertices[i] * rotation;
			vertices[i] = vertices[i] + center;
		}
	}

    float left = item.rect.x;
    float top = item.rect.y;
    float right = item.rect.x + item.rect.z;
    float bottom = item.rect.y + item.rect.w;

	if (bool(item.options & OPTIONS_FLIP_X)) {
		float temp = left;
		left = right;
		right = temp;
	}

	if (bool(item.options & OPTIONS_FLIP_Y)) {
		float temp = top;
		top = bottom;
		bottom = temp;
	}

    vec2 uv_array[6] = {
        vec2(left, top),
        vec2(left, bottom),
        vec2(right, top),
        vec2(right, top),
        vec2(left, bottom),
        vec2(right, bottom)
    };

    vec2 vertex_pos = vertices[gl_VertexID];
    gl_Position = orthographic_projection * vec4(vertex_pos, 0.0, 1.0);
    uv = uv_array[gl_VertexID];
	material_id = item.material_id;
	world_position = vertex_pos.xy;

}