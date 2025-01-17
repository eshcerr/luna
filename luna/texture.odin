package luna

import "core:fmt"
import "core:image/png"
import gl "vendor:OpenGL"

texture_t :: struct {
	id: u32,
}

texture_init :: proc(image: ^png.Image) -> (t: texture_t = {}) {
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
		i32(image.width),
		i32(image.height),
		0,
		gl.RGBA,
		gl.UNSIGNED_BYTE,
		raw_data(image.pixels.buf),
    )
    
	gl.GenerateMipmap(gl.TEXTURE_2D)
	return
}

texture_deinit :: proc (t: ^texture_t) {
    gl.DeleteTextures(1, &t.id)
}
