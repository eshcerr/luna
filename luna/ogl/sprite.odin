package luna_ogl

import "core:strings"
import stbi "vendor:stb/image"

sprite_t :: struct {
	data:                    [^]byte,
	width, height, channels: i32,
}

sprite_from_png :: proc(file: string) -> sprite_t {
	sprite := sprite_t{}

	sprite.data = stbi.load(strings.clone_to_cstring(file), &sprite.width, &sprite.height, &sprite.channels, 0)
    assert(sprite.data != nil, "failed to load sprite")
    return sprite
}

@(deprecated="not implemented yet")
sprite_from_ase :: proc(file: string) -> sprite_t {
	sprite := sprite_t{}
    return sprite
}

sprite_deinit :: proc (sprite: ^sprite_t) {
    stbi.image_free(sprite.data)
}
