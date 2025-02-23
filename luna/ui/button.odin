package luna_ui

import "../base"
import "../core"
import "../gfx"

ui_context_space_e :: enum {
    CAMERA,
    WORLD,
}

ui_context_t :: struct {
    font: ^gfx.font_t,    
    root: ui_element_t,
    space: ui_context_space_e,
    camera: ^gfx.camera_t,
    mouse_pos : base.ivec2,
}



ui_context_process_inputs :: proc(ctx: ^ui_context_t, inputs: ^core.input_t) {
    switch ctx.space {
    case .WORLD: 
        ctx.mouse_pos = gfx.camera_screen_to_world(ctx.camera, inputs.mouse.mouse_pos)
    case .CAMERA: 
        ctx.mouse_pos = inputs.mouse.mouse_pos
    }
    ui_element_process_inputs(ctx.root, inputs)
}

ui_element_process_inputs :: proc(ctx, ^ui_context_t, elem: ^ui_element_t, inputs: ^core.input_t) {
    if elem.state == .HIDDEN || elem.state == .DISABLED { return }

    #partial switch elem.element {
    case ^ui_container:
        for child_element in elem.element.(^ui_container_t).children {
            ui_element_process_inputs(child_element, inputs)
        }
    case button_t:
        if core.iaabb_contains(ctx.mouse_pos){
            
        }
    }
}


ui_element_state_e :: enum { 
    HIDDEN,
    DISABLED,
    ENABLED,
}

ui_element_t :: struct {
    state:                      ui_element_state_e,
    element: union {
        ^ui_container_t,
        button_t,
        slider_t,
        label_t,
        text_filed_t,
    },
    bounding_box:               base.iaabb,
    padding, margin, border:    base.ivec4,
    corner_rounding: base.ivec4
}

ui_container_layout_e :: enum {
    PANEL,
    FLEX,
    SCROLL,
}

ui_container_flow_e :: enum { 
    HORIZONTAL,
    VERTICAL,
    BOTH,
}

ui_container_t :: struct {
    layout:         ui_container_layout_e,
    flow_direction: ui_container_flow_e,
    children:       [dynamic]ui_element_t,
}

button_state_e :: enum {
    NONE,
    HOVERED,
    PRESSED,
}

button_t :: struct {
    state: button_state_e,
    text: string,
}

toggle_t :: struct {
    value: bool,
}

radio_button_group_t :: struct {
    buttons:                [dynamic]radio_button_t,
    selected_button_index:  i32,
}

radio_button_t :: struct {
    group: ^radio_button_group_t,
    value: bool,
}

slider_t :: struct {
    value, min_value, max_value: f32,
}

label_t :: struct {
    text: string,
}

text_box_state_e :: enum {
    NONE,
    HOVERED,
    SELECTED,
}

text_field_t :: struct {
    state: text_box_state_e,
    text, template: string,
}

combo_box_t :: struct {
    state: text_box_state_e,
    text, template: string,
    fields: ^[?]string,
}
