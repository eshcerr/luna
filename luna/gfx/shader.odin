package luna_gfx

import "../base"

import "core:os"
import "core:strings"

import gl "vendor:OpenGL"

SHADER_ORTHOGRAPHIC_PROJ_UNIFORM :: "orthographic_projection"

GLSL_VERSION :: "#version 430 core\n"

GLSL_VERTEX_SHADER :: `
struct batch_item_t {
    ivec4 rect;
    vec2 position;
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
layout (location = 1) out uint material_id;

uint OPTIONS_FLIP_X = 1 << 0;
uint OPTIONS_FLIP_Y = 1 << 1;

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

	mat2 rotation;
	rotation[0] = vec2(cos(item.rotation), -sin(item.rotation));
	rotation[1] = vec2(sin(item.rotation), cos(item.rotation));

	vec2 center = item.position + vec2(item.rect.z * item.scale.x, item.rect.w * item.scale.y) / 2.0;
	
	for (int i = 0; i <= 6; i++) {
		vertices[i] = vertices[i] - center;
		vertices[i] = vertices[i] * rotation;
		vertices[i] = vertices[i] + center;
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
`


GLSL_FRAGMENT_SHADER :: `
struct material_t {
	vec4 color;
};

layout (std430, binding = 1) buffer materials_sbo {
    material_t materials[];
};

layout (location = 0) in vec2 uv;
layout (location = 1) in flat uint material_id;

layout (location = 0) out vec4 frag_color;

layout (binding = 0) uniform sampler2D texture_atlas;

void main()
{
	material_t material = materials[material_id];
    vec4 tex_color = texelFetch(texture_atlas, ivec2(uv), 0);
`


GLSL_SPRITE_FRAGMENT_SHADER :: `
    if (tex_color.a == 0.0) { discard; }
    frag_color = tex_color * material.color;
`


GLSL_FONT_FRAGMENT_SHADER :: `
    if (tex_color.r == 0.0) { discard; }
    frag_color = tex_color.r * material.color;
`


shader_t :: struct {
	program: u32,
}

shader_type_e :: enum {
	SPRITE,
	FONT,
}

shader_init :: proc {
	shader_init_from_files,
	shader_init_and_generate,
}

shader_init_from_files :: proc(vert_path, frag_path: string) -> shader_t {
	program, is_ok := gl.load_shaders_file(vert_path, frag_path)
	assert(is_ok, "shader loading failed")
	return {program = program}
}

shader_init_and_generate :: proc(file_path: string, shader_type: shader_type_e) -> shader_t {
	vertex_source, fragment_source := shader_generate_sources(file_path, shader_type)

	vertex, vertex_compile_ok := gl.compile_shader_from_source(
		vertex_source,
		gl.Shader_Type.VERTEX_SHADER,
	)
	assert(vertex_compile_ok, "failed to compile vertex shader sources")
	
	fragment, fragment_compile_ok := gl.compile_shader_from_source(
		fragment_source,
		gl.Shader_Type.FRAGMENT_SHADER,
	)
	assert(fragment_compile_ok, "failed to compile vertex shader sources")

	program, program_link_ok := gl.create_and_link_program({vertex, fragment})
	assert(program_link_ok, "failed to link shader program")

	gl.DeleteShader(vertex)
	gl.DeleteShader(fragment)

	return {program = program}
}

shader_generate_sources :: proc(
	shader_path: string,
	shader_type: shader_type_e,
) -> (
	string,
	string,
) {
	shader_token_e :: enum {
		VERTEX_VARIABLES_BEGIN,
		VERTEX_VARIABLES_END,
		VERTEX_VARIABLES_NO,
		VERTEX_BEGIN,
		VERTEX_END,
		VERTEX_NO,
		FRAGMENT_VARIABLES_BEGIN,
		FRAGMENT_VARIABLES_END,
		FRAGMENT_VARIABLES_NO,
		FRAGMENT_BEGIN,
		FRAGMENT_END,
		FRAGMENT_NO,
	}

	@(static) SHADER_TOKENS := [shader_token_e]string {
		.VERTEX_VARIABLES_BEGIN   = "@vert_variables",
		.VERTEX_VARIABLES_END     = "@end_vert_variables",
		.VERTEX_VARIABLES_NO      = "@no_vert_variables",
		.VERTEX_BEGIN             = "@vert", // start a vertex shader code block
		.VERTEX_END               = "@end_vert", // end a vertex shader block code
		.VERTEX_NO                = "@no_vert", // specify that there will be no vertex shader code
		.FRAGMENT_VARIABLES_BEGIN = "@frag_variables",
		.FRAGMENT_VARIABLES_END   = "@end_frag_variables",
		.FRAGMENT_VARIABLES_NO    = "@no_frag_variables",
		.FRAGMENT_BEGIN           = "@frag", // start a fragment shader code block
		.FRAGMENT_END             = "@end_frag", // end a fragment shader block code
		.FRAGMENT_NO              = "@no_frag", // specify that there will be no fragment shader code
	}

	check_tokens :: proc(source: string, begin, end, no: shader_token_e) -> (has_source: bool) {
		has_no_source := strings.contains(source, SHADER_TOKENS[no])
		has_source =
			strings.contains(source, SHADER_TOKENS[begin]) ||
			strings.contains(source, SHADER_TOKENS[end])

		assert(
			!(has_no_source && has_source),
			strings.concatenate(
				{
					"cannot use both ",
					SHADER_TOKENS[begin],
					"/",
					SHADER_TOKENS[end],
					" and ",
					SHADER_TOKENS[no],
					" in the same file.",
				},
			),
		)
		return
	}

	file_source, is_ok := os.read_entire_file_from_filename(shader_path)
	assert(is_ok, strings.concatenate({"failed to read file content of: ", shader_path}))
	source := strings.trim_space(string(file_source))

	has_vertex_variables_token := check_tokens(
		source,
		.VERTEX_VARIABLES_BEGIN,
		.VERTEX_VARIABLES_END,
		.VERTEX_VARIABLES_NO,
	)
	has_vertex_token := check_tokens(source, .VERTEX_BEGIN, .VERTEX_END, .VERTEX_NO)
	has_fragment_variables_token := check_tokens(
		source,
		.FRAGMENT_VARIABLES_BEGIN,
		.FRAGMENT_VARIABLES_END,
		.FRAGMENT_VARIABLES_NO,
	)
	has_fragment_token := check_tokens(source, .FRAGMENT_BEGIN, .FRAGMENT_END, .FRAGMENT_NO)


	vertex_variables_source, fragment_variables_source: string = "", ""
	vertex_source, fragment_source: string = "", ""

	if has_vertex_variables_token {
		vertex_variables_source = shader_extract_code(
			source,
			SHADER_TOKENS[.VERTEX_BEGIN],
			SHADER_TOKENS[.VERTEX_END],
		)
	}

	if has_vertex_token {
		vertex_source = shader_extract_code(
			source,
			SHADER_TOKENS[.VERTEX_BEGIN],
			SHADER_TOKENS[.VERTEX_END],
		)
	}

	if has_fragment_variables_token {
		fragment_variables_source = shader_extract_code(
			source,
			SHADER_TOKENS[.FRAGMENT_BEGIN],
			SHADER_TOKENS[.FRAGMENT_END],
		)
	}

	if has_fragment_token {
		fragment_source = shader_extract_code(
			source,
			SHADER_TOKENS[.FRAGMENT_BEGIN],
			SHADER_TOKENS[.FRAGMENT_END],
		)
	}

	final_vertex_source, final_fragment_source: string

	final_vertex_source = strings.concatenate(
		{GLSL_VERSION, vertex_variables_source, GLSL_VERTEX_SHADER, vertex_source, "\n}"},
	)

	if shader_type == .SPRITE {
		final_fragment_source = strings.concatenate(
			{
				GLSL_VERSION,
				fragment_variables_source,
				GLSL_FRAGMENT_SHADER,
				GLSL_SPRITE_FRAGMENT_SHADER,
				fragment_source,
				"\n}",
			},
		)
	} else {
		final_fragment_source = strings.concatenate(
			{
				GLSL_VERSION,
				fragment_variables_source,
				GLSL_FRAGMENT_SHADER,
				GLSL_FONT_FRAGMENT_SHADER,
				fragment_source,
				"\n}",
			},
		)
	}

	return final_vertex_source, final_fragment_source
}

shader_extract_code :: proc(source, begin_token, end_token: string) -> string {
	start_index := strings.index(source, begin_token)
	assert(start_index != -1, strings.concatenate({begin_token, " not found"}))
	start_index += len(begin_token)

	end_index := strings.index(source[start_index:], end_token)
	assert(start_index != -1, strings.concatenate({end_token, " not found"}))

	return strings.trim_space(source[start_index:start_index + end_index])
}

shader_deinit :: proc(shader: ^shader_t) {
	gl.DeleteProgram(shader.program)
}

shader_set_vec2 :: proc(shader: ^shader_t, name: string, v: base.vec2) {
	gl.Uniform2f(gl.GetUniformLocation(shader.program, strings.clone_to_cstring(name)), v.x, v.y)
}

shader_seti :: proc(shader: ^shader_t, name: string, v: i32) {
	gl.Uniform1i(gl.GetUniformLocation(shader.program, strings.clone_to_cstring(name)), v)
}

shader_setf :: proc(shader: ^shader_t, name: string, v: f32) {
	gl.Uniform1f(gl.GetUniformLocation(shader.program, strings.clone_to_cstring(name)), v)
}
