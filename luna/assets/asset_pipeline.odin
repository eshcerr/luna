package luna_assets

import "core:strings"
import "core:encoding/json" 
// TODO : json serialisation and deserialisation
// TODO : json animation save load

// TODO : ressource management pipeline

asset_type_e :: enum {
	IMAGE,
	SHADER,
	FONT,
	BAKED_FONT,
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
