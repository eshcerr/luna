package luna_assets

import "core:strings"

asset_type_e :: enum {
	IMAGE,
	SHADER,
	SFX,
	DATA,
	COUNT,
}

asset_pipeline_t :: struct {
	paths: [asset_type_e.COUNT]string,
}

pip: ^asset_pipeline_t

get_path :: proc(asset_type: asset_type_e, path: string) -> string {
	return strings.concatenate({pip.paths[asset_type], path})
}
