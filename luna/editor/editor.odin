package luna_editor

import imgui "../../vendor/odin-imgui"
import "base:runtime"
import "core:fmt"
import "core:path/slashpath"
import "core:slice"
import "core:strings"

import assets "../assets"
import luna_ecs "../core/ecs"

editor_t :: struct {
	ctx:   editor_ctx_t,
	state: editor_state_t,
}

editor_ctx_t :: struct {
	ecs:                   ^luna_ecs.ecs_t,
	asset_manager:         ^assets.asset_manager_t,
	selected_entity:       luna_ecs.entity_t,
	selected_asset_folder: string,
	selected_asset_id:     u32,
	asset_tag_filter:      string,
	asset_search:          [256]byte,
}

editor_state_t :: struct {
	show_hierarchy: bool,
	show_inspector: bool,
	show_scene:     bool,
	show_assets:    bool,
}

editor_init :: proc() -> ^editor_t {
	editor := new(editor_t)
	editor.state = {true, true, true, true}
	editor.ctx = {nil, nil, 0, "", 0, "", {}}
	return editor
}

editor_deinit :: proc(editor: ^editor_t) {
	free(editor)
}

editor_layout :: proc(editor: ^editor_t) {
	viewport := imgui.GetMainViewport()
	imgui.SetNextWindowPos(viewport.WorkPos)
	imgui.SetNextWindowSize(viewport.WorkSize)
	imgui.SetNextWindowViewport(viewport.ID_)

	window_flags: imgui.WindowFlags = {
		.MenuBar,
		.NoDocking,
		.NoTitleBar,
		.NoResize,
		.NoCollapse,
		.NoMove,
		.NoBringToFrontOnFocus,
		.NoNavFocus,
		.NoBackground,
	}

	imgui.PushStyleVar(.WindowRounding, 0)
	imgui.PushStyleVar(.WindowBorderSize, 0)
	imgui.PushStyleVarX(.WindowPadding, 0)
	imgui.PushStyleVarY(.WindowPadding, 0)

	imgui.Begin("dockspace", nil, window_flags)
	defer imgui.End()

	imgui.PopStyleVar(4)

	// menu
	if imgui.BeginMenuBar() {
		defer imgui.EndMenuBar()

		if imgui.BeginMenu("file") {
			defer imgui.EndMenu()

			if imgui.MenuItem("new scene") {
				fmt.println("new scene")
			}
			if imgui.MenuItem("save scene") {
				fmt.println("save scene")
			}
			imgui.Separator()
			if imgui.MenuItem("exit") {
				fmt.println("exit")
			}
		}

		if imgui.BeginMenu("entity") {
			defer imgui.EndMenu()

			if imgui.MenuItem("create entity") {
				entity := luna_ecs.ecs_create_entity(editor.ctx.ecs)
				fmt.println("created entity %d", entity)
			}
		}

		if imgui.BeginMenu("window") {
			defer imgui.EndMenu()

			if imgui.MenuItem("hierarchy", "") {
				editor.state.show_hierarchy = !editor.state.show_hierarchy
			}
			if imgui.MenuItem("inspector", "") {
				editor.state.show_inspector = !editor.state.show_inspector
			}
			if imgui.MenuItem("scene", "") {
				editor.state.show_scene = !editor.state.show_scene
			}
			if imgui.MenuItem("assets", "") {
				editor.state.show_assets = !editor.state.show_assets
			}
		}
	}

	dockspace_id := imgui.GetID("dockspace")
	imgui.DockSpace(dockspace_id, imgui.Vec2{0, 0}, {})

	if imgui.DockBuilderGetNode(dockspace_id) == nil {
		imgui.DockBuilderRemoveNode(dockspace_id)
		imgui.DockBuilderAddNode(dockspace_id, {})
		imgui.DockBuilderSetNodeSize(dockspace_id, viewport.WorkSize)

		dock_left := imgui.DockBuilderSplitNode(dockspace_id, .Left, 0.2, nil, &dockspace_id)
		dock_right := imgui.DockBuilderSplitNode(dockspace_id, .Right, 0.25, nil, &dockspace_id)
		dock_bottom := imgui.DockBuilderSplitNode(dockspace_id, .Down, 0.3, nil, &dockspace_id)

		imgui.DockBuilderDockWindow("hierarchy", dock_left)
		imgui.DockBuilderDockWindow("inspector", dock_right)
		imgui.DockBuilderDockWindow("assets", dock_bottom)
		// Scene/Game windows will go in the central area

		imgui.DockBuilderFinish(dockspace_id)
	}

	// Show windows
	if editor.state.show_hierarchy {
		editor_hierarchy_window(editor)
	}
	if editor.state.show_inspector {
		editor_inspector_window(editor)
	}
	if editor.state.show_scene {
		editor_scene_window(editor)
	}
	if editor.state.show_assets {
		editor_assets_window(editor)
	}
}

editor_hierarchy_window :: proc(editor: ^editor_t) {
	if !imgui.Begin("hierarchy", &editor.state.show_hierarchy) {
		imgui.End()
		return
	}
	defer imgui.End()

	entity_set := make(map[luna_ecs.entity_t]bool, context.temp_allocator)

	for type_id, storage in editor.ctx.ecs.components {
		for entity in storage.entities {
			entity_set[entity] = true
		}
	}

	for entity in entity_set {
		context.allocator = context.temp_allocator
		label := fmt.tprintf("entity %d", entity)

		flags: imgui.TreeNodeFlags = {.Leaf, .SpanAvailWidth}
		if editor.ctx.selected_entity == entity {
			flags += {.Selected}
		}

		node_open := imgui.TreeNodeEx(strings.clone_to_cstring(label), flags)

		if imgui.IsItemClicked() {
			editor.ctx.selected_entity = entity
		}

		if node_open {
			imgui.TreePop()
		}
	}
}

editor_inspector_window :: proc(editor: ^editor_t) {
	if !imgui.Begin("inspector", &editor.state.show_inspector) {
		imgui.End()
		return
	}
	defer imgui.End()

	if editor.ctx.selected_entity == 0 {
		imgui.Text("no entity selected")
		return
	}

	context.allocator = context.temp_allocator

	imgui.Text("entity %d", editor.ctx.selected_entity)
	imgui.Separator()

	for type_id, storage in editor.ctx.ecs.components {
		if editor.ctx.selected_entity not_in storage.entity_to_index do continue

		index := storage.entity_to_index[editor.ctx.selected_entity]
		component_ptr := storage.data[index]

		type_info := type_info_of(type_id)
		component_name := type_info.variant.(runtime.Type_Info_Named).name

		editor_inspect_component(component_name, component_ptr, type_id)
	}
}

editor_scene_window :: proc(editor: ^editor_t) {
	if !imgui.Begin(
		"scene",
		&editor.state.show_scene,
		{.NoScrollbar, .NoScrollWithMouse, .NoBackground},
	) {
		imgui.End()
		return
	}
	defer imgui.End()

	// draw render target here
	// get the available space for rendering
	available := imgui.GetContentRegionAvail()
	imgui.Text("viewport size: %.0f x %.0f", available.x, available.y)
}

editor_inspect_component :: proc(name: string, ptr: rawptr, type_id: typeid) {
	context.allocator = context.temp_allocator

	label := strings.clone_to_cstring(name)

	if imgui.TreeNodeEx(label, {.SpanAvailWidth}) {
		defer imgui.TreePop()

		info := runtime.type_info_base(type_info_of(type_id))

		#partial switch variant in info.variant {
		case runtime.Type_Info_Struct:
			struct_info := variant

			imgui.Indent()
			defer imgui.Unindent()

			for i: i32 = 0; i < struct_info.field_count; i += 1 {
				field_ptr := rawptr(uintptr(ptr) + struct_info.offsets[i])
				field_name := strings.clone_to_cstring(struct_info.names[i])
				field_type := struct_info.types[i]

				imgui.PushID(field_name)
				defer imgui.PopID()

				#partial switch field_variant in field_type.variant {
				case runtime.Type_Info_Integer:
					handle_integer_field(field_name, field_ptr, field_type.id)

				case runtime.Type_Info_Float:
					handle_float_field(field_name, field_ptr, field_type.id)

				case runtime.Type_Info_Boolean:
					imgui.Checkbox(field_name, auto_cast field_ptr)

				case runtime.Type_Info_String:
					handle_string_field(field_name, field_ptr)

				case runtime.Type_Info_Array:
					handle_array_field(field_name, field_ptr, field_variant)

				case runtime.Type_Info_Named:
					#partial switch variant in field_variant.base.variant {
					case runtime.Type_Info_Struct:
						handle_nested_struct(field_name, field_ptr, field_type.id)
					}
				}
			}
		}
	}
}

editor_assets_window :: proc(editor: ^editor_t) {
	if !imgui.Begin("assets explorer", &editor.state.show_assets) {
		imgui.End()
		return
	}
	defer imgui.End()

	if editor.ctx.asset_manager == nil {
		imgui.Text("no asset manager loaded")
		return
	}

	context.allocator = context.temp_allocator

	available := imgui.GetContentRegionAvail()

	if imgui.BeginChild("folders", imgui.Vec2{200, 0}) {
		editor_draw_folder_tree(editor)
	}
	imgui.EndChild()

	imgui.SameLine()
	imgui.SeparatorEx({.Vertical})
	imgui.SameLine()

	if imgui.BeginChild("assets", imgui.Vec2{0, 0}) {
		editor_draw_asset_grid(editor)
	}
	imgui.EndChild()
}

@(private)
editor_draw_folder_tree :: proc(editor: ^editor_t) {
	context.allocator = context.temp_allocator

	manager := editor.ctx.asset_manager

	// Root folder
	flags: imgui.TreeNodeFlags = {.SpanAvailWidth}
	if editor.ctx.selected_asset_folder == "" {
		flags += {.Selected}
	}

	if imgui.TreeNodeEx("Root", flags) {
		defer imgui.TreePop()

		if imgui.IsItemClicked() {
			editor.ctx.selected_asset_folder = ""
		}

		// Collect all unique folders
		folders_set := make(map[string]bool)
		defer delete(folders_set)

		for id, asset in manager.assets {
			if asset.v_folder != "" {
				folders_set[asset.v_folder] = true

				// Also add parent folders
				parts := strings.split(asset.v_folder, "/")
				defer delete(parts)

				current := ""
				for part in parts {
					if current != "" {
						current = strings.concatenate({current, "/", part})
					} else {
						current = part
					}
					folders_set[current] = true
				}
			}
		}

		// Convert to sorted array
		folders := make([dynamic]string)
		defer delete(folders)

		for folder in folders_set {
			append(&folders, folder)
		}

		// Sort alphabetically
		slice.sort_by(folders[:], proc(a, b: string) -> bool {
			return a < b
		})

		// Build top-level folders (no slashes)
		root_folders := make([dynamic]string)
		defer delete(root_folders)

		for folder in folders {
			if !strings.contains(folder, "/") {
				append(&root_folders, folder)
			}
		}

		// Draw top-level folders
		for folder in root_folders {
			editor_draw_folder_node(editor, folder, folders[:])
		}
	}
}

@(private)
editor_draw_folder_node :: proc(editor: ^editor_t, folder: string, all_folders: []string) {
	context.allocator = context.temp_allocator

	flags: imgui.TreeNodeFlags = {.SpanAvailWidth}
	if editor.ctx.selected_asset_folder == folder {
		flags += {.Selected}
	}

	has_children := false
	for f in all_folders {
		if strings.has_prefix(f, folder) && f != folder {
			parts := strings.split(f, "/")
			defer delete(parts)

			parent_parts := strings.split(folder, "/")
			defer delete(parent_parts)

			if len(parts) == len(parent_parts) + 1 {
				has_children = true
				break
			}
		}
	}

	if !has_children {
		flags += {.Leaf}
	}

	folder_name := folder
	if last_slash := strings.last_index(folder, "/"); last_slash >= 0 {
		folder_name = folder[last_slash + 1:]
	}
	node_open := imgui.TreeNodeEx(strings.clone_to_cstring(folder_name), flags)

	if imgui.IsItemClicked() {
		editor.ctx.selected_asset_folder = folder
	}

	if node_open {
		defer imgui.TreePop()

		if has_children {
			for f in all_folders {
				if strings.has_prefix(f, folder) && f != folder {
					parts := strings.split(f, "/")
					defer delete(parts)

					parent_parts := strings.split(folder, "/")
					defer delete(parent_parts)

					if len(parts) == len(parent_parts) + 1 {
						editor_draw_folder_node(editor, f, all_folders)
					}
				}
			}
		}
	}
}

@(private)
editor_draw_asset_grid :: proc(editor: ^editor_t) {
	context.allocator = context.temp_allocator

	manager := editor.ctx.asset_manager

	imgui.Text(
		"folder: %s",
		editor.ctx.selected_asset_folder == "" ? "root" : strings.clone_to_cstring(editor.ctx.selected_asset_folder),
	)

	imgui.Separator()

	imgui.SetNextItemWidth(200)
	imgui.InputTextWithHint(
		"##search",
		"search assets...",
		cstring(raw_data(&editor.ctx.asset_search)),
		len(editor.ctx.asset_search),
	)

	imgui.SameLine()

	imgui.SetNextItemWidth(150)
	if imgui.BeginCombo(
		"##tagfilter",
		editor.ctx.asset_tag_filter == "" ? "all tags" : strings.clone_to_cstring(editor.ctx.asset_tag_filter),
	) {
		defer imgui.EndCombo()

		if imgui.Selectable("all tags", editor.ctx.asset_tag_filter == "") {
			editor.ctx.asset_tag_filter = ""
		}

		tags := make(map[string]bool)
		defer delete(tags)

		for id, asset in manager.assets {
			for tag in asset.tags {
				tags[tag] = true
			}
		}

		for tag in tags {
			is_selected := editor.ctx.asset_tag_filter == tag
			if imgui.Selectable(strings.clone_to_cstring(tag), is_selected) {
				editor.ctx.asset_tag_filter = tag
			}
		}
	}


	assets_to_display := make([dynamic]u32)
	defer delete(assets_to_display)

	for id, asset in manager.assets {
		if asset.v_folder != editor.ctx.selected_asset_folder do continue

		search_text := string(cstring(raw_data(&editor.ctx.asset_search)))
		if search_text != "" {
			if !strings.contains(strings.to_lower(asset.name), strings.to_lower(search_text)) {
				continue
			}
		}

		if editor.ctx.asset_tag_filter != "" {
			has_tag := false
			for tag in asset.tags {
				if tag == editor.ctx.asset_tag_filter {
					has_tag = true
					break
				}
			}
			if !has_tag {
				continue
			}
		}

		append(&assets_to_display, id)
	}

	available := imgui.GetContentRegionAvail()
	icon_size: f32 = 80
	padding: f32 = 10
	columns := i32(max(1, (available.x - padding) / (icon_size + padding)))

	imgui.BeginChild("asset_scroll_region", imgui.Vec2{0, 0}, {}, {.HorizontalScrollbar})
	defer imgui.EndChild()

	if len(assets_to_display) == 0 {
		imgui.Text("No assets in this folder")
	} else {
		columns_per_row := i32(max(1, available.x / (icon_size + padding)))

		for &asset_id, idx in assets_to_display {
			asset := &manager.assets[asset_id]

			if idx % int(columns_per_row) != 0 {
				imgui.SameLine()
			}

			// Use idx instead of asset_id for PushID to avoid ID conflicts
			id_str := fmt.tprintf("asset_%d", idx)
			imgui.PushID(strings.clone_to_cstring(id_str))
			defer imgui.PopID()

			// Asset button
			is_selected := editor.ctx.selected_asset_id == asset_id
			if is_selected {
				imgui.PushStyleColorImVec4(.Button, imgui.Vec4{0.3, 0.5, 0.8, 1.0})
				defer imgui.PopStyleColor()
			}

			imgui.BeginGroup()
			defer imgui.EndGroup()

			button_label := fmt.tprintf("##asset_%d", idx)
			if imgui.Button(
				strings.clone_to_cstring(button_label),
				imgui.Vec2{icon_size, icon_size},
			) {
				editor.ctx.selected_asset_id = asset_id
				fmt.println("selected asset:", asset.name)
			}

			if imgui.IsItemHovered() && imgui.IsMouseDoubleClicked(.Left) {
				fmt.println("open asset:", asset.path)
			}

			if imgui.BeginDragDropSource({}) {
				defer imgui.EndDragDropSource()

				imgui.SetDragDropPayload("ASSET_ID", &asset_id, size_of(u32), {})
				imgui.Text("dragging: %s", strings.clone_to_cstring(asset.name))
			}

			draw_list := imgui.GetWindowDrawList()
			p := imgui.GetItemRectMin()

			color: u32
			#partial switch asset.type {
			case .IMAGE:
				color = imgui.GetColorU32ImVec4(imgui.Vec4{1.0, 0.3, 0.6, 1.0})
			case .SPRITE:
				color = imgui.GetColorU32ImVec4(imgui.Vec4{0.3, 0.6, 1.0, 1.0})
			case .ATLAS:
				color = imgui.GetColorU32ImVec4(imgui.Vec4{0.6, 0.3, 1.0, 1.0})
			case .ANIMATION:
				color = imgui.GetColorU32ImVec4(imgui.Vec4{1.0, 0.6, 0.3, 1.0})
			case .SHADER:
				color = imgui.GetColorU32ImVec4(imgui.Vec4{0.6, 1.0, 0.3, 1.0})
			case .FONT:
				color = imgui.GetColorU32ImVec4(imgui.Vec4{1.0, 1.0, 0.3, 1.0})
			case .BAKED_FONT:
				color = imgui.GetColorU32ImVec4(imgui.Vec4{1.0, 0.9, 0.3, 1.0})
			case .SFX:
				color = imgui.GetColorU32ImVec4(imgui.Vec4{0.3, 1.0, 0.6, 1.0})
			//case .DATA:       color = imgui.GetColorU32ImVec4(imgui.Vec4{0.7, 0.7, 0.7, 1.0})
			case:
				color = imgui.GetColorU32ImVec4(imgui.Vec4{0.5, 0.5, 0.5, 1.0})
			}

			imgui.DrawList_AddRectFilled(
				draw_list,
				imgui.Vec2{p.x + padding, p.y + padding},
				imgui.Vec2{p.x + icon_size - padding, p.y + icon_size - padding},
				color,
				5.0,
			)

			imgui.PushTextWrapPos(imgui.GetCursorPosX() + icon_size)

			// Truncate long names
			display_name := asset.name[:(min(len(asset.name), 22))]
			imgui.Text(strings.clone_to_cstring(display_name))

			imgui.PopTextWrapPos()

			if imgui.IsItemHovered() {
				imgui.SetTooltip(strings.clone_to_cstring(asset.name))
			}

			if len(asset.tags) > 0 {
				imgui.PushStyleColorImVec4(.Text, imgui.Vec4{0.6, 0.6, 0.6, 1.0})
				defer imgui.PopStyleColor()

				tags_str := strings.join(asset.tags[:], ", ")
				defer delete(tags_str)

				imgui.TextWrapped(strings.clone_to_cstring(fmt.tprintf("[%s]", tags_str)))
			}

			popup_id := fmt.tprintf("ctx_%d", idx)
			if imgui.BeginPopupContextItem(strings.clone_to_cstring(popup_id)) {
				defer imgui.EndPopup()

				if imgui.MenuItem("Open") {
					fmt.println("Open:", asset.path)
				}

				imgui.Separator()

				if imgui.BeginMenu("Add Tag") {
					defer imgui.EndMenu()

					@(static) new_tag_buf: [128]byte
					imgui.InputText("##newtag", cstring(raw_data(&new_tag_buf)), len(new_tag_buf))

					if imgui.Button("Add") {
						tag := string(cstring(raw_data(&new_tag_buf)))
						if tag != "" {
							assets.asset_manager_add_tag(manager, asset_id, tag)
						}
					}
				}

				if len(asset.tags) > 0 && imgui.BeginMenu("Remove Tag") {
					defer imgui.EndMenu()

					for tag in asset.tags {
						if imgui.MenuItem(strings.clone_to_cstring(tag)) {
							assets.asset_manager_remove_tag(manager, asset_id, tag)
						}
					}
				}

				imgui.Separator()

				if imgui.MenuItem("Delete") {
					fmt.println("Delete:", asset.path)
				}
			}
		}
	}

	// Asset count
	imgui.Separator()
	imgui.Text("%d assets", len(assets_to_display))
}


@(private)
handle_integer_field :: proc(name: cstring, ptr: rawptr, type_id: typeid) {
	switch type_id {
	case i32, u32:
		imgui.InputInt(name, auto_cast ptr, 1)
	case u8, u16:
		imgui.InputInt(name, auto_cast ptr, 1)
	case u64:
		imgui.InputScalar(name, .U64, auto_cast ptr)
	case:
		imgui.Text("%s: <unsupported int type>", name)
	}
}

@(private)
handle_float_field :: proc(name: cstring, ptr: rawptr, type_id: typeid) {
	switch type_id {
	case f32:
		imgui.InputFloat(name, auto_cast ptr, 0.1)
	case f64:
		imgui.InputScalar(name, .Double, auto_cast ptr)
	case:
		imgui.Text("%s: <unsupported float type>", name)
	}
}


@(private)
handle_string_field :: proc(name: cstring, ptr: rawptr) {
	buf: [1024]byte
	copy(buf[:], (^string)(ptr)^)

	if imgui.InputText(name, cstring(raw_data(&buf)), len(buf), {.EnterReturnsTrue}) {
		new_len := 0
		for b, i in buf {
			if b == 0 {
				new_len = i
				break
			}
		}
		// Free old string if it was allocated
		(^string)(ptr)^ = strings.clone_from_bytes(buf[:new_len])
	}
}

@(private)
handle_array_field :: proc(name: cstring, ptr: rawptr, array_info: runtime.Type_Info_Array) {
	elem_type := array_info.elem.id
	count := array_info.count

	// Handle common numeric array types
	if count >= 2 && count <= 4 {
		switch elem_type {
		case i32:
			switch count {
			case 2:
				imgui.InputInt2(name, auto_cast ptr)
			case 3:
				imgui.InputInt3(name, auto_cast ptr)
			case 4:
				imgui.InputInt4(name, auto_cast ptr)
			}
		case f32:
			switch count {
			case 2:
				imgui.InputFloat2(name, auto_cast ptr)
			case 3:
				imgui.InputFloat3(name, auto_cast ptr)
			case 4:
				imgui.InputFloat4(name, auto_cast ptr)
			}
		case:
			imgui.Text("%s: [%d]%v", name, count, elem_type)
		}
	} else {
		imgui.Text("%s: [%d]%v", name, count, elem_type)
	}
}


@(private)
handle_nested_struct :: proc(name: cstring, ptr: rawptr, type_id: typeid) {
	context.allocator = context.temp_allocator

	if imgui.TreeNode(name) {
		defer imgui.TreePop()

		info := runtime.type_info_base(type_info_of(type_id)).variant.(runtime.Type_Info_Struct)

		for i: i32 = 0; i < info.field_count; i += 1 {
			field_ptr := rawptr(uintptr(ptr) + info.offsets[i])
			field_name := strings.clone_to_cstring(info.names[i])
			field_type := info.types[i]

			imgui.PushID(field_name)
			defer imgui.PopID()

			#partial switch variant in field_type.variant {
			case runtime.Type_Info_Integer:
				handle_integer_field(field_name, field_ptr, field_type.id)

			case runtime.Type_Info_Float:
				handle_float_field(field_name, field_ptr, field_type.id)

			case runtime.Type_Info_Boolean:
				imgui.Checkbox(field_name, auto_cast field_ptr)

			case runtime.Type_Info_String:
				handle_string_field(field_name, field_ptr)

			case runtime.Type_Info_Array:
				handle_array_field(field_name, field_ptr, variant)

			case runtime.Type_Info_Named:
				#partial switch variant in variant.base.variant {
				case runtime.Type_Info_Struct:
					handle_nested_struct(field_name, field_ptr, field_type.id)
				}
			}
		}
	}
}
