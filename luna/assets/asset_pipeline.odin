package luna_assets

import "core:image"
import "core:fmt"
import "core:os"
import "core:path/slashpath"
import "core:time"

import "core:strings"

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
	TEXTURE,
	SPRITE,
	ATLAS,
	ANIMATION,
	UNKNOWN,
}

asset_metadata_t :: struct {
	name:          string,
	type:          asset_type_e,
	editor_folder: string,
	tags:          [dynamic]string,
}

asset_t :: struct {
	metadata: asset_metadata_t,
	id:            u32,
	path:          string,
	full_path:     string,
	file_size:     i64,
	modified:      time.Time,
	loaded:        bool,
	handle:        rawptr,
}

asset_file_t :: struct {
	metadata: asset_metadata_t,
	data: asset_data_t,
}

asset_data_t :: union {
	sprite_asset_t,
	atlas_asset_t,
}

asset_manager_t :: struct {
	assets:        map[u32]asset_t,
	path_to_id:    map[string]u32,
	tags_index:    map[string][dynamic]u32,
	folder_index:  map[string][dynamic]u32,
	type_index:    map[asset_type_e][dynamic]u32,
	next_id:       u32,
	root_path:     string,
	watch_changes: bool,
}

asset_query_t :: struct {
	types:  []asset_type_e,
	tags:   []string,
	folder: string,
}

asset_manager_init :: proc(root_path: string) -> ^asset_manager_t {
	manager := new(asset_manager_t)
	manager.assets = make(map[u32]asset_t)
	manager.path_to_id = make(map[string]u32)
	manager.tags_index = make(map[string][dynamic]u32)
	manager.folder_index = make(map[string][dynamic]u32)
	manager.type_index = make(map[asset_type_e][dynamic]u32)
	manager.next_id = 1
	manager.root_path = root_path
	manager.watch_changes = false

	return manager
}

asset_manager_deinit :: proc(manager: ^asset_manager_t) {
	for id, &asset in manager.assets {
		if asset.loaded && asset.handle != nil {
			// switch deinit asset per type
			// do an array of proc to be called with a rawptr
			// and call it from asset.type
		}
		delete(asset.tags)
	}

	delete(manager.assets)
	delete(manager.path_to_id)

	for _, &list in manager.tags_index {
		delete(list)
	}
	delete(manager.tags_index)

	for _, &list in manager.folder_index {
		delete(list)
	}
	delete(manager.folder_index)

	for _, &list in manager.type_index {
		delete(list)
	}
	delete(manager.type_index)

	free(manager)
}

detect_asset_type :: proc(path: string) -> asset_type_e {
	ext := slashpath.ext(path)
	ext_lower := strings.to_lower(ext)
	defer delete(ext_lower)

	switch ext_lower {
	case ".png", ".jpg", ".bmp":
		return .IMAGE
	case ".glsl", ".frag", ".vert", ".shader":
		return .SHADER
	case ".ttf":
		return .FONT
	case ".wav", ".mp3", ".ogg":
		return .SFX
	case ".atlas":
		return .ATLAS
	case ".anim":
		return .ANIMATION
	case:
		return .UNKNOWN
	}
}

asset_manager_register :: proc(
	manager: ^asset_manager_t,
	rel_path: string,
	folder := "",
	type: asset_type_e = nil,
) -> u32 {
	if id, exists := manager.path_to_id[rel_path]; exists {
		return id
	}

	full_path := slashpath.join({manager.root_path, rel_path})
	file_info, err := os.stat(full_path)
	if err != nil {
		fmt.eprintln("failed to stat file:", full_path, err)
		return 0
	}

	id := manager.next_id
	manager.next_id += 1

	asset_type := (type != nil ? type : detect_asset_type(rel_path))
	name := "unnamed"
	if last_slash := strings.last_index(rel_path, "/"); last_slash >= 0 {
		name = rel_path[last_slash + 1:]
	}

	asset := asset_t {
		id            = id,
		name          = name,
		path          = strings.clone(rel_path),
		full_path     = strings.clone(full_path),
		type          = asset_type,
		editor_folder = folder,
		tags          = make([dynamic]string),
		file_size     = file_info.size,
		modified      = file_info.modification_time,
		loaded        = false,
		handle        = nil,
	}

	manager.assets[id] = asset
	manager.path_to_id[asset.path] = id

	if folder != "" {
		if folder not_in manager.folder_index {
			manager.folder_index[folder] = make([dynamic]u32)
		}
		append(&manager.folder_index[folder], id)
	}

	if asset.type not_in manager.type_index {
		manager.type_index[asset.type] = make([dynamic]u32)
	}
	append(&manager.type_index[asset.type], id)

	return id
}

asset_manager_scan :: proc(manager: ^asset_manager_t, directory := "", folder := "") {
	scan_path :=
		directory == "" ? manager.root_path : slashpath.join({manager.root_path, directory})

	handle, err := os.open(scan_path)
	if err != nil {
		fmt.eprintln("failed to open directory:", scan_path, err)
		return
	}
	defer os.close(handle)

	file_infos, read_err := os.read_dir(handle, -1)
	if read_err != nil {
		fmt.eprintln("failed to read directory:", scan_path, read_err)
		return
	}
	defer os.file_info_slice_delete(file_infos)

	for info in file_infos {
		full_path := slashpath.join({scan_path, info.name})
		rel_path := directory == "" ? info.name : slashpath.join({directory, info.name})

		if info.is_dir {
			sub_folder := folder == "" ? info.name : slashpath.join({folder, info.name})
			asset_manager_scan(manager, rel_path, sub_folder)
		} else {
			asset_manager_register(manager, rel_path, folder)
		}
	}
}

asset_manager_get :: proc(manager: ^asset_manager_t, id: u32) -> ^asset_t {
	if id in manager.assets do return &manager.assets[id]
	return nil
}

asset_manager_get_by_path :: proc(manager: ^asset_manager_t, path: string) -> ^asset_t {
	if id, exists := manager.path_to_id[path]; exists do return &manager.assets[id]
	return nil
}

asset_manager_add_tag :: proc(manager: ^asset_manager_t, asset_id: u32, tag: string) {
	asset := asset_manager_get(manager, asset_id)
	if asset == nil do return

	for existing_tag in asset.tags {
		if tag == existing_tag do return
	}

	append(&asset.tags, tag)

	if tag not_in manager.tags_index {
		manager.tags_index[tag] = make([dynamic]u32)
	}
	append(&manager.tags_index[tag], asset_id)
}

asset_manager_remove_tag :: proc(manager: ^asset_manager_t, asset_id: u32, tag: string) {
	asset := asset_manager_get(manager, asset_id)
	if asset == nil do return

	for t, i in asset.tags {
		if t == tag {
			delete(asset.tags[i])
			ordered_remove(&asset.tags, i)
			break
		}
	}

	if tag in manager.tags_index {
		for id, i in manager.tags_index[tag] {
			if id == asset_id {
				ordered_remove(&manager.tags_index[tag], i)
				break
			}
		}
	}
}

asset_manager_query_by_tag :: proc(manager: ^asset_manager_t, tag: string) -> []u32 {
	if tag in manager.tags_index do return manager.tags_index[tag][:]
	return nil
}

asset_manager_query_by_folder :: proc(manager: ^asset_manager_t, folder: string) -> []u32 {
	if folder in manager.folder_index do return manager.folder_index[folder][:]
	return nil
}

asset_manager_query_by_type :: proc(manager: ^asset_manager_t, type: asset_type_e) -> []u32 {
	if type in manager.type_index do return manager.type_index[type][:]
	return nil
}

asset_manager_query :: proc(manager: ^asset_manager_t, query: asset_query_t) -> [dynamic]u32 {
	results := make([dynamic]u32)

	candidates := make(map[u32]bool)
	defer delete(candidates)

	for id in manager.assets {
		candidates[id] = true
	}

	if len(query.types) > 0 {
		type_matches := make(map[u32]bool)
		defer delete(type_matches)

		for type in query.types {
			if ids := asset_manager_query_by_type(manager, type); ids != nil {
				for id in ids {
					type_matches[id] = true
				}
			}
		}

		for id in candidates {
			if id not_in type_matches {
				delete_key(&candidates, id)
			}
		}
	}

	if len(query.tags) > 0 {
		tag_matches := make(map[u32]bool)
		defer delete(tag_matches)

		for tag in query.tags {
			if ids := asset_manager_query_by_tag(manager, tag); ids != nil {
				for id in ids {
					tag_matches[id] = true
				}
			}
		}

		for id in candidates {
			if id not_in tag_matches {
				delete_key(&candidates, id)
			}
		}
	}

	if query.folder != "" {
		for id in candidates {
			for asset_id in manager.folder_index[query.folder] {
				if id != asset_id {
					delete_key(&candidates, id)
				}
			}
		}
	}

	for id in candidates {
		append(&results, id)
	}

	return results
}
