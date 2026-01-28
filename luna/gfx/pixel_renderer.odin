package luna_gfx

import "../base"
import gl "vendor:OpenGL"

// to future me, i made the decision to change my old rendering method to this one.
// this rendering method is based on the only two devlogs made by aarthificial on his pixel renderer.
// it will allow me to have post process shaders, smooth layers rendering for
// paralax layers and even top down layers, difered pixelated lights, upscaling and normal maps.


viewport_t :: struct {
	dimension: base.ivec2,
}

pixel_renderer_t :: struct {
	native_size:    base.vec2,
	display_size:   base.vec2,
	upscale_factor: f32,

	// buffers
	color_buffer:   render_texture_t,
	normal_buffer:  render_texture_t,
	light_buffer:   render_texture_t,
	final_buffer:   render_texture_t,

	// fullscreen quads for post process
	fullscreen_vao: u32,
	fullscreen_vbo: u32,
}

render_texture_t :: struct {
	gpu_id:     u32,
	texture_id: u32,
	dimension:  base.ivec2,
}

render_texture_bind :: proc(target: ^render_texture_t) -> bool {
	gl.GenFramebuffers(1, &target.gpu_id)
	gl.BindFramebuffer(gl.FRAMEBUFFER, target.gpu_id)

	gl.GenTextures(1, &target.texture_id)
	gl.BindTexture(gl.TEXTURE_2D, target.texture_id)
	gl.TexImage2D(
		gl.TEXTURE_2D,
		0,
		gl.SRGB8_ALPHA8,
		target.dimension.x,
		target.dimension.y,
		0,
		gl.RGBA,
		gl.UNSIGNED_BYTE,
		nil,
	)

	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)

	gl.FramebufferTexture2D(
		gl.FRAMEBUFFER,
		gl.COLOR_ATTACHMENT0,
		gl.TEXTURE_2D,
		target.texture_id,
		0,
	)

	gl.DrawBuffer(gl.COLOR_ATTACHMENT0)

	status := gl.CheckFramebufferStatus(gl.FRAMEBUFFER)
	return status != gl.FRAMEBUFFER_COMPLETE
}

render_texture_use :: proc(target: ^render_texture_t) {
	gl.BindFramebuffer(gl.FRAMEBUFFER, target.gpu_id)
	gl.Viewport(0, 0, target.dimension.x, target.dimension.y)
}

render_texture_clear :: proc(viewport: ^viewport_t) {
	gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
	gl.Viewport(0, 0, viewport.dimension.x, viewport.dimension.y)
}

render_texture_draw_to_render_texture :: proc(
	src: ^render_texture_t,
	dst: ^render_texture_t,
	shader: ^shader_t,
	fullscreen_vao: u32,
) {
	gl.BindFramebuffer(gl.FRAMEBUFFER, dst.gpu_id)
    gl.Viewport(0, 0, dst.dimension.x, dst.dimension.y)
    
    gl.ClearColor(0, 0, 0, 1)
    gl.Clear(gl.COLOR_BUFFER_BIT)
    
    gl.Disable(gl.DEPTH_TEST)
    gl.Disable(gl.BLEND)
    
    gl.ActiveTexture(gl.TEXTURE0)
    gl.BindTexture(gl.TEXTURE_2D, src.texture_id)  // FIXED: bind src, not dst
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
    
    gl.UseProgram(shader.program)
    gl.Uniform1i(gl.GetUniformLocation(shader.program, "u_tex"), 0)
    
    gl.BindVertexArray(fullscreen_vao)
    gl.DrawArrays(gl.TRIANGLES, 0, 6)
    
    gl.BindVertexArray(0)
    gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
}

normal_map_t :: struct {
	texture: ^texture2D_t,
}


// draw sprites in color_texture
// draw normals in normal_texture
// either calculate them or give them via parameter

// calculate each light separated
// multiply by the base color
// add for each light result
// = shaded color

// light:
// create a mesh for the light
// on normals it applies with : normal_falloff = clamp(dot(dir_to_light, normal_vec), 0.0, 1.0)
// final = intensity * radial_falloff(calculated in frag) * angular_falloff (calculated in frag) * normal_falloff
pixel_light_t :: struct {
	// color of the light
	tint:                 base.vec3,

	// brightness of the light
	intensity:            f32,

	// volume of the light, act as if there was fog to  display the light on
	// this value is multiplied by the calculated light color and added to the output color
	volumetric_intensity: f32,

	// how fast the light attenuates
	// in frag : = pow(1.0 - distance, 2.0)
	radial_falloff:       f32,

	// limit the light to a specific angle range
	// in frag : = smoothstep(max_angle, min_angle, angle)
	angular_falloff:      f32,
}
