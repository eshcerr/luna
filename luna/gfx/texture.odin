package luna_gfx

import gl "vendor:OpenGL"

texture_t :: struct {
	id:     u32,
	sprite: ^sprite_t,
}

texture_wrap_option_e :: enum {
	CLAMP,
	CLAMP_TO_EDGE,
	REPEAT,
}

texture_init :: proc(
	sprite: ^sprite_t,
	wrap_option: texture_wrap_option_e = .CLAMP_TO_EDGE,
) -> texture_t {
	t := texture_t{}
	t.sprite = sprite

	gl.GenTextures(1, &t.id)
	gl.BindTexture(gl.TEXTURE_2D, t.id)

	wrap: i32
	switch wrap_option {
	case .CLAMP:
		wrap = gl.CLAMP
	case .CLAMP_TO_EDGE:
		wrap = gl.CLAMP_TO_EDGE
	case .REPEAT:
		wrap = gl.REPEAT
	}

	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, wrap)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, wrap)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

	gl.TexImage2D(
		gl.TEXTURE_2D,
		0,
		gl.SRGB8_ALPHA8,
		i32(sprite.width),
		i32(sprite.height),
		0,
		gl.RGBA,
		gl.UNSIGNED_BYTE,
		&sprite.data[0],
	)

	gl.GenerateMipmap(gl.TEXTURE_2D)
	return t
}

texture_deinit :: proc(t: ^texture_t) {
	gl.DeleteTextures(1, &t.id)
}
