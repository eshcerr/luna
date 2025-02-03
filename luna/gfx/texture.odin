package luna_gfx

import "../core"

import "core:fmt"
import gl "vendor:OpenGL"

texture_t :: struct {
	id:     u32,
	sprite: ^core.sprite_t,
}

texture_init :: proc(sprite: ^core.sprite_t) -> texture_t {
	t := texture_t{}
	t.sprite = sprite

	gl.GenTextures(1, &t.id)
	gl.BindTexture(gl.TEXTURE_2D, t.id)

	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
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
