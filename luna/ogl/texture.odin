package luna

import "core:fmt"
import gl "vendor:OpenGL"

texture_t :: struct {
	id: u32,
}

texture_init :: proc(sprite: ^sprite_t) -> (t: texture_t = {}) {
	gl.GenTextures(1, &t.id)
	gl.BindTexture(gl.TEXTURE_2D, t.id)

    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

	gl.TexImage2D(
		gl.TEXTURE_2D,
		0,
		gl.RGBA,
		i32(sprite.width),
		i32(sprite.height),
		0,
		gl.RGBA,
		gl.UNSIGNED_BYTE,
		&sprite.data[0],
    )
    
	gl.GenerateMipmap(gl.TEXTURE_2D)
	return
}

texture_deinit :: proc (t: ^texture_t) {
    gl.DeleteTextures(1, &t.id)
}
