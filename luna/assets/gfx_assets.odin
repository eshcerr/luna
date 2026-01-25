package luna_assets

import "../gfx"

sprite_asset_t :: struct {
	image_path: string,
	pivot: base.vec2,
}

atlas_asset_t :: struct {
	image_path: string,
	rects: []gfx.atlas_rect_t,
}

init_from_asset :: proc {
    init_sprite_from_asset,
    init_atlas_from_asset,
}

init_sprite_from_asset :: proc(asset: atlas_asset_t) -> ^gfx.sprite_t {
}


init_atlas_from_asset :: proc(asset: atlas_asset_t) -> ^gfx.atlas_t{

}