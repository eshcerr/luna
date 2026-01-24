#version 430 core

struct point_light_t {
    vec3 color;
    ivec2 position;
    float intensity;
    float constant;
    float linear;
    float quadratic;
};

struct spot_light_t {
    vec3 color;
    vec2 direction;
    ivec2 position;
    float intensity;
    float constant;
    float linear;
    float quadratic;
	float cutoff;
	float smooth_cutoff;
};

struct material_t {
	vec4 color;
};

layout (std430, binding = 1) buffer materials_sbo {
    material_t materials[];
};

layout (std430, binding = 2) buffer point_light_sbo {
    point_light_t point_lights[];
};

layout (std430, binding = 3) buffer spot_light_sbo {
    spot_light_t spot_lights[];
};

uniform int point_light_count;
uniform int spot_light_count;

layout (location = 0) in vec2 uv;
layout (location = 1) in flat uint material_id;
layout (location = 2) in vec2 world_position;

layout (location = 0) out vec4 frag_color;

layout (binding = 0) uniform sampler2D texture_atlas;
layout (binding = 1) uniform sampler2D normal_map;

uniform vec3 global_light_color;
uniform mat4 orthographic_projection;


vec3 calculate_point_light(struct point_light_t light) {
	float distance = length(world_position - light.position);
	float attenuation = light.intensity / (light.constant, light.linear * distance + light.quadratic * distance * distance);
	return clamp(light.color * light.intensity * attenuation, 0.0, 1.0);
}

vec3 calculate_spot_light(struct spot_light_t light) {
	vec2 light_to_fragment = normalize(world_position - light.position);
	float theta = dot(light_to_fragment, normalize(light.direction));

	if (theta > light.smooth_cutoff) {
		float intensity = clamp((theta - light.smooth_cutoff) / (light.cutoff - light.smooth_cutoff), 0.0, 1.0);
		float distance = length(world_position - light.position);
		float attenuation = light.intensity / (light.constant, light.linear * distance + light.quadratic * distance * distance);
		return clamp(light.color * light.intensity * attenuation * intensity, 0.0, 1.0);
	}

    return vec3(0, 0, 0);
}
	
vec3 calculate_lights() {
//	vec3 color = vec3(0, 0, 0);
//
//	for (int i = 0; i < point_light_count; i++) {
//		color += calculate_point_light(point_lights[i]);
//	}
//
//	for (int i = 0; i < spot_light_count; i++) {
//		color += calculate_spot_light(spot_lights[i]);
//	}
//
//	return global_light_color + color;
	return global_light_color;
}

void main()
{
	material_t material = materials[material_id];
    vec4 tex_color = texelFetch(texture_atlas, ivec2(uv), 0);

    if (tex_color.a == 0.0) { discard; }
    frag_color = tex_color * material.color * vec4(calculate_lights(), 1);

}