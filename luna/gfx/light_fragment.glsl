#version 330 core

in vec2 v_uv;
in vec2 v_world_pos;

out vec4 FragColor;

uniform sampler2D u_normal_tex;
uniform sampler2D u_position_tex;

uniform vec2 u_light_pos;
uniform vec3 u_light_color;
uniform float u_light_intensity;
uniform float u_light_radius;
uniform float u_light_volumetric_intensity;

uniform vec2 u_light_direction;
uniform float u_inner_angle;
uniform float u_outer_angle;

void main() {
    vec3 normal = texture(u_normal_tex, v_uv).rgb;
    vec2 pixel_pos = v_world_pos;

    vec2 to_light = u_light_pos - pixel_pos;
    float dist = length(to_light);
    
    if (dist > u_light_radius) {
        discard;
    }

    vec2 light_dir = normalize(to_light);

    float radial_falloff = pow(1.0 - clamp(dist / u_light_radius, 0.0, 1.0), 2.0);

    vec3 light_dir_3d = vec3(light_dir, 0.0);
    float normal_falloff = max(dot(normal, light_dir_3d), 0.0);

    float angular_falloff = 1.0;

    if (u_outer_angle > 0.0) {
        vec2 to_pixel = normalize(pixel_pos - u_light_pos);
        float angle = dot(to_pixel, normalize(u_light_direction));
        float min_angle = cos(u_outer_angle);
        float max_angle = cos(u_inner_angle);
        angular_falloff = smoothstep(min_angle, max_angle, angle);
    }

    float attenuation = radial_falloff * normal_falloff * angular_falloff;
    vec3 light = u_light_color * u_light_intensity * attenuation;

    vec3 volumetric = u_light_color * u_light_volumetric_intensity * radial_falloff * angular_falloff;

    FragColor = vec4(light + volumetric, 1.0);
}