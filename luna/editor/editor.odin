package luna_editor

import imgui "../../vendor/odin-imgui"
import "base:runtime"
import "core:fmt"
import "core:strings"

import luna_ecs "../core/ecs"
editor_t :: struct {
    ctx:   editor_ctx_t,
    state: editor_state_t,
}

editor_ctx_t :: struct {
    ecs:             ^luna_ecs.ecs_t,
    selected_entity: luna_ecs.entity_t,
}

editor_state_t :: struct {
    show_hierarchy: bool,
    show_inspector: bool,
    show_scene:     bool,
}

editor_init :: proc() -> ^editor_t {
    editor := new(editor_t)
    editor.state = {true, true, true}
    editor.ctx = {nil, 0}
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
        
        imgui.DockBuilderDockWindow("hierarchy", dock_left)
        imgui.DockBuilderDockWindow("inspector", dock_right)
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
        
        editor_inspect_component(
            component_name,
            component_ptr,
            type_id,
            editor.ctx.selected_entity,
        )
    }
}

editor_scene_window :: proc(editor: ^editor_t) {
    if !imgui.Begin("scene", &editor.state.show_scene, {.NoScrollbar, .NoScrollWithMouse, .NoBackground}) {
        imgui.End()
        return
    }
    defer imgui.End()
    
    // draw render target here    
    // get the available space for rendering
    available := imgui.GetContentRegionAvail()
    imgui.Text("viewport size: %.0f x %.0f", available.x, available.y)
}

editor_inspect_component :: proc(
	name: string,
	ptr: rawptr,
	type_id: typeid,
	entity: luna_ecs.entity_t,
) {
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
