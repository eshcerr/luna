package luna_gfx

import "../base"

import "core:c"
import "core:fmt"
import "core:mem"
import "core:os"
import "core:strings"

import stbi "vendor:stb/image"
import stbtt "vendor:stb/truetype"

FONT_CHARACTER_BEGIN :: 32
FONT_CHARACTER_END :: 127

font_t :: struct {
	info:        stbtt.fontinfo,
	font_height: i32,
	glyphs:      [FONT_CHARACTER_END - FONT_CHARACTER_BEGIN]stbtt.packedchar,
	quads:       [FONT_CHARACTER_END - FONT_CHARACTER_BEGIN]stbtt.aligned_quad,
}

font_bake :: proc(
	path, png_output_path: string,
	font_size: i32,
	font_atlas_size: base.ivec2,
) -> ^font_t {

	font := new(font_t)
	font.font_height = font_size

	content, err := os.read_entire_file(path)
	assert(content != nil, strings.concatenate({"couldn't read file: ", path}))

	assert(
		bool(stbtt.InitFont(&font.info, &content[0], 0)),
		strings.concatenate({"failed to init font: ", path}),
	)

	atlas_data, _ := mem.alloc(int(font_atlas_size.x * font_atlas_size.y))
	defer mem.free(atlas_data)

	ctx: stbtt.pack_context

	stbtt.PackBegin(&ctx, auto_cast atlas_data, font_atlas_size.x, font_atlas_size.y, 0, 1, nil)
	stbtt.PackFontRange(
		&ctx,
		&content[0],
		0,
		auto_cast font_size,
		FONT_CHARACTER_BEGIN,
		FONT_CHARACTER_END - FONT_CHARACTER_BEGIN,
		&font.glyphs[0],
	)
	stbtt.PackEnd(&ctx)

	for i in 0 ..< (FONT_CHARACTER_END - FONT_CHARACTER_BEGIN) {
		unused: base.vec2
		stbtt.GetPackedQuad(
			&font.glyphs[0],
			font_atlas_size.x,
			font_atlas_size.y,
			c.int(i),
			&unused.x,
			&unused.y,
			&font.quads[i],
			false,
		)
	}

	stbi.write_png(
		strings.clone_to_cstring(png_output_path),
		font_atlas_size.x,
		font_atlas_size.y,
		1,
		atlas_data,
		font_atlas_size.x,
	)

	return font
}

font_deinit :: proc(font: ^font_t) {
	free(font)
}

font_get_glyph_rect :: proc(font: ^font_t, character: rune) -> base.iaabb {
	glyph_index := character - FONT_CHARACTER_BEGIN
	char: stbtt.packedchar = font.glyphs[i32(glyph_index)]
	rect: base.iaabb
	rect.x = i32(char.x0)
	rect.y = i32(char.y0)
	rect.z = i32(char.x1 - char.x0)
	rect.w = i32(char.y1 - char.y0)
	return rect
}

font_get_glyph_offset :: proc(font: ^font_t, character: rune) -> base.vec2 {
	glyph_index := character - FONT_CHARACTER_BEGIN
	char: stbtt.packedchar = font.glyphs[i32(glyph_index)]
	return {char.xoff, char.yoff}
}
