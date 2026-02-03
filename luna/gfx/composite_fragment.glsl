#version 330 core

in vec2 v_uv;

out vec4 FragColor;

uniform sampler2D u_color_tex;
uniform sampler2D u_light_tex;
uniform float u_ambient = 0.1; // ambient light, will surely change

void main() {
    vec4 color = texture(u_color_tex, v_uv);
    vec3 light = texture(u_light_tex, v_uv).rgb;

    vec3 final_color = color.rgb * (light + vec3(u_ambient));

    FragColor = vec4(final_color, color.a);
}