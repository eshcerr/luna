package luna_ui

import "../base"
import "../gfx"

ui_context_t :: struct {
    font: ^gfx.font_t,    
    root: ui_element_t,
}

ui_element_state_e :: enum { 
    HIDDEN,
    DISABLED,
    ENABLED,
}

ui_element_t :: struct {
    state: ui_element_state_e,
    element: union {
        ^ui_container_t,
        button_t,
        slider_t,
        label_t,
        text_filed_t,
    },
    bounding_box: base.iaabb,
    padding, margin, border:base.ivec4,
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

ui_container :: struct {
    layout:         ui_container_layout_e,
    flow_direction: ui_container_flow_e,
    children:       [dynamic]ui_element_t,
}

button_t :: struct {
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

text_field_t :: struct {
    text, template: string,
}

combo_box_t :: struct {
    text, template: string,
    fields: ^[?]string
}
