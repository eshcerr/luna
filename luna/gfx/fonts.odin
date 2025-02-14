package luna_gfx

import "../base"

import "core:c"
import "core:fmt"
import "core:mem"
import "core:os"
import "core:strings"

import stbi "vendor:stb/image"
import stbtt "vendor:stb/truetype"

BITMAP_WIDTH :: 512
BITMAP_HEIGHT :: 512

CHAR_BEGIN :: 32
CHAR_END :: 127

font_t :: struct {
	info:   stbtt.fontinfo,
	glyphs: [CHAR_END - CHAR_BEGIN]stbtt.packedchar, // 127 may change
	quads:  [CHAR_END - CHAR_BEGIN]stbtt.aligned_quad,
}

font_init :: proc(path: string, font_size: i32) -> font_t {

	font: font_t

	content, err := os.read_entire_file(path)
	assert(content != nil, strings.concatenate({"couldn't read file: ", path}))

	assert(
		bool(stbtt.InitFont(&font.info, &content[0], 0)),
		strings.concatenate({"failed to init font: ", path}),
	)

	atlas_data, _ := mem.alloc(BITMAP_WIDTH * BITMAP_HEIGHT)

	ctx: stbtt.pack_context

	stbtt.PackBegin(&ctx, auto_cast atlas_data, BITMAP_WIDTH, BITMAP_HEIGHT, 0, 1, nil)
	stbtt.PackFontRange(
		&ctx,
		&content[0],
		0,
		auto_cast font_size,
		CHAR_BEGIN,
		CHAR_END - CHAR_BEGIN,
	)
	stbtt.PackEnd(&ctx)

	for i in 0 ..< (CHAR_END - CHAR_BEGIN) {
		unused: base.vec2
		stbtt.GetPackedQuad(
			&font.glyphs[0],
			BITMAP_WIDTH,
			BITMAP_HEIGHT,
			c.int(i),
			&unused.x,
			&unused.y,
			&font.quads[i],
			false,
		)
	}

	stbi.write_png("font.png", BITMAP_WIDTH, BITMAP_HEIGHT, 1, atlas_data, BITMAP_WIDTH)

	return font
}
