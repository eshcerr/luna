//#+feature dynamic-literals
package luna_core

import "../base"
import "../gfx"

import "core:c"
import "core:fmt"
import "core:strings"
import "core:math"
import "core:math/linalg"
import "vendor:glfw"

INPUT_MAXIMUM_BUTTONS_PER_ACTION :: 4
GAMEPAD_AXIS_DEADZONE :: 0.1

keycode_e :: enum {
	KEY_A,
	KEY_B,
	KEY_C,
	KEY_D,
	KEY_E,
	KEY_F,
	KEY_G,
	KEY_H,
	KEY_I,
	KEY_J,
	KEY_K,
	KEY_L,
	KEY_M,
	KEY_N,
	KEY_O,
	KEY_P,
	KEY_Q,
	KEY_R,
	KEY_S,
	KEY_T,
	KEY_U,
	KEY_V,
	KEY_W,
	KEY_X,
	KEY_Y,
	KEY_Z,
	KEY_0,
	KEY_1,
	KEY_2,
	KEY_3,
	KEY_4,
	KEY_5,
	KEY_6,
	KEY_7,
	KEY_8,
	KEY_9,
	KEY_SPACE,
	KEY_APOSTROPHE,
	KEY_MINUS,
	KEY_EQUAL,
	KEY_LEFT_BRACKET,
	KEY_RIGHT_BRACKET,
	KEY_SEMICOLON,
	KEY_QUOTE,
	KEY_COMMA,
	KEY_PERIOD,
	KEY_FORWARD_SLASH,
	KEY_BACKWARD_SLASH,
	KEY_TAB,
	KEY_ESCAPE,
	KEY_PAUSE,
	KEY_UP,
	KEY_DOWN,
	KEY_LEFT,
	KEY_RIGHT,
	KEY_BACKSPACE,
	KEY_RETURN,
	KEY_DELETE,
	KEY_INSERT,
	KEY_HOME,
	KEY_END,
	KEY_PAGE_UP,
	KEY_PAGE_DOWN,
	KEY_CAPS_LOCK,
	KEY_NUM_LOCK,
	KEY_SCROLL_LOCK,
	KEY_MENU,
	KEY_LEFT_SHIFT,
	KEY_RIGHT_SHIFT,
	KEY_LEFT_CONTROL,
	KEY_RIGHT_CONTROL,
	KEY_LEFT_ALT,
	KEY_RIGHT_ALT,
	KEY_LEFT_SUPER,
	KEY_RIGHT_SUPER,
	KEY_F1,
	KEY_F2,
	KEY_F3,
	KEY_F4,
	KEY_F5,
	KEY_F6,
	KEY_F7,
	KEY_F8,
	KEY_F9,
	KEY_F10,
	KEY_F11,
	KEY_F12,
	KEY_NUMPAD_0,
	KEY_NUMPAD_1,
	KEY_NUMPAD_2,
	KEY_NUMPAD_3,
	KEY_NUMPAD_4,
	KEY_NUMPAD_5,
	KEY_NUMPAD_6,
	KEY_NUMPAD_7,
	KEY_NUMPAD_8,
	KEY_NUMPAD_9,
	KEY_NUMPAD_STAR,
	KEY_NUMPAD_PLUS,
	KEY_NUMPAD_MINUS,
	KEY_NUMPAD_DOT,
	KEY_NUMPAD_SLASH,
	KEY_NUMPAD_ENTER,
	KEY_NUMPAD_DECIMAL,
	COUNT = 255,
}

mouse_buttons_e :: enum {
	MOUSE_BUTTON_1,
	MOUSE_BUTTON_2,
	MOUSE_BUTTON_3,
	MOUSE_BUTTON_4,
	MOUSE_BUTTON_5,
	MOUSE_BUTTON_6,
	MOUSE_BUTTON_7,
	MOUSE_BUTTON_8,
	COUNT,
}

gamepad_buttons_e :: enum {
	GAMEPAD_BUTTON_A,
	GAMEPAD_BUTTON_B,
	GAMEPAD_BUTTON_X,
	GAMEPAD_BUTTON_Y,
	GAMEPAD_BUTTON_DPAD_LEFT,
	GAMEPAD_BUTTON_DPAD_RIGHT,
	GAMEPAD_BUTTON_DPAD_UP,
	GAMEPAD_BUTTON_DPAD_DOWN,
	GAMEPAD_BUTTON_LEFT_TRIGGER,
	GAMEPAD_BUTTON_RIGHT_TRIGGER,
	GAMEPAD_BUTTON_LEFT_BUMPER,
	GAMEPAD_BUTTON_RIGHT_BUMPER,
	GAMEPAD_BUTTON_BACK,
	GAMEPAD_BUTTON_START,
	GAMEPAD_BUTTON_GUIDE,
	COUNT,
}

glfw_key_lookup_table: map[c.int]keycode_e
glfw_mouse_buttons_lookup_table: map[c.int]mouse_buttons_e
glfw_gamepad_buttons_lookup_table: map[c.int]gamepad_buttons_e

button_t :: struct {
	is_down, just_pressed, just_released: bool,
	half_transition_count:                u8,
}

keyboard_t :: struct {
	keys: [keycode_e.COUNT]button_t,
}

mouse_t :: struct {
	delta:                                 base.ivec2,
	prev_mouse_pos, mouse_pos:             base.ivec2,
	prev_mouse_pos_world, mouse_pos_world: base.ivec2,
	buttons:                               [mouse_buttons_e.COUNT]button_t,
}

gamepad_t :: struct {
	left_stick, right_stick, dpad: base.vec2,
	left_trigger, right_trigger:   f32,
	buttons:                       [gamepad_buttons_e.COUNT]button_t,
}

input_t :: struct {
	screen_size: base.ivec2,
	mouse:       mouse_t,
	keyboard:    keyboard_t,
	gamepad:     gamepad_t,
    input_mapping: input_mapping_t
}

input_actions_e :: enum {
    MOVE_LEFT,
    MOVE_RIGHT,
    MOVE_UP,
    MOVE_DOWN,
    JUMP,
}

input_mapping_t :: struct {
    actions: map[i32]input_action_t,
}

input_action_t :: struct {
    buttons: [INPUT_MAXIMUM_BUTTONS_PER_ACTION]^button_t,
}

input: input_t = {}

inputs_deinit :: proc() {
	clear_map(&glfw_key_lookup_table)
	clear_map(&glfw_mouse_buttons_lookup_table)
	clear_map(&glfw_gamepad_buttons_lookup_table)
	delete_map(glfw_key_lookup_table)
	delete_map(glfw_mouse_buttons_lookup_table)
	delete_map(glfw_gamepad_buttons_lookup_table)
}

inputs_update :: proc() {
	for &key in input.keyboard.keys {
		key.just_pressed = false
		key.just_released = false
		key.half_transition_count = 0
	}

	for &button in input.mouse.buttons {
		button.just_pressed = false
		button.just_released = false
		button.half_transition_count = 0
	}

	for &button in input.gamepad.buttons {
		button.just_pressed = false
		button.just_released = false
		button.half_transition_count = 0
	}
}

inputs_update_mouse :: proc(window: glfw.WindowHandle) {
	x, y := glfw.GetCursorPos(window)

	input.mouse.prev_mouse_pos = input.mouse.mouse_pos
	input.mouse.prev_mouse_pos_world = input.mouse.mouse_pos_world

	input.mouse.mouse_pos = base.ivec2{i32(x), i32(y)}
	input.mouse.mouse_pos_world = base.vec2_to_ivec2(
		gfx.camera_screen_to_world(&gfx.pip.game_camera, input.mouse.mouse_pos),
	)

	input.mouse.delta = input.mouse.prev_mouse_pos - input.mouse.mouse_pos
}


inputs_update_gamepad :: proc() {
	if glfw.JoystickPresent(0) && glfw.JoystickIsGamepad(0) {
		state: glfw.GamepadState
		if glfw.GetGamepadState(0, &state) != 0 {
			for i in 0 ..= glfw.GAMEPAD_BUTTON_LAST {
				is_down: bool =
					(state.buttons[i32(i)] == glfw.PRESS || state.buttons[i32(i)] == glfw.REPEAT)
				button_code := glfw_gamepad_buttons_lookup_table[i32(i)]
				p_button := &input.gamepad.buttons[button_code]

				p_button.just_pressed = !p_button.just_pressed && !p_button.is_down && is_down
				p_button.just_released = !p_button.just_released && p_button.is_down && !is_down
				p_button.is_down = is_down
				p_button.half_transition_count += 1
			}

			input.gamepad.dpad = base.vec2 {
				(input.gamepad.buttons[gamepad_buttons_e.GAMEPAD_BUTTON_DPAD_LEFT].is_down ? -1 : 0) +
				(input.gamepad.buttons[gamepad_buttons_e.GAMEPAD_BUTTON_DPAD_RIGHT].is_down ? 1 : 0),
				(input.gamepad.buttons[gamepad_buttons_e.GAMEPAD_BUTTON_DPAD_UP].is_down ? -1 : 0) +
				(input.gamepad.buttons[gamepad_buttons_e.GAMEPAD_BUTTON_DPAD_DOWN].is_down ? 1 : 0),
			}
			input.gamepad.dpad = linalg.vector_normalize(input.gamepad.dpad)

			apply_deadzone :: proc(v: f32) -> f32 {
				if math.abs(v) < GAMEPAD_AXIS_DEADZONE {return 0.0}
				return(
					(v - (GAMEPAD_AXIS_DEADZONE * (v > 0 ? 1 : -1))) /
					(1.0 - GAMEPAD_AXIS_DEADZONE) \
				)
			}

			input.gamepad.left_stick = base.vec2 {
				apply_deadzone(state.axes[glfw.GAMEPAD_AXIS_LEFT_X]),
				apply_deadzone(state.axes[glfw.GAMEPAD_AXIS_LEFT_Y]),
			}

			input.gamepad.right_stick = base.vec2 {
				apply_deadzone(state.axes[glfw.GAMEPAD_AXIS_RIGHT_X]),
				apply_deadzone(state.axes[glfw.GAMEPAD_AXIS_RIGHT_Y]),
			}

			input.gamepad.left_trigger = state.axes[glfw.GAMEPAD_AXIS_LEFT_TRIGGER]
			input.gamepad.right_trigger = state.axes[glfw.GAMEPAD_AXIS_RIGHT_TRIGGER]
		}
	}
}

inputs_pressed :: proc {
	inputs_key_pressed,
	inputs_mouse_button_pressed,
	inputs_gamepad_button_pressed,
	inputs_action_pressed,
}

inputs_released :: proc {
	inputs_key_released,
	inputs_mouse_button_released,
	inputs_gamepad_button_released,
	inputs_action_released,
}

inputs_down :: proc {
	inputs_key_down,
	inputs_mouse_button_down,
	inputs_gamepad_button_down,
	inputs_action_down,
}


inputs_key_pressed :: proc(keycode: keycode_e) -> bool {
	return input.keyboard.keys[keycode].just_pressed
}

inputs_key_released :: proc(keycode: keycode_e) -> bool {
	return input.keyboard.keys[keycode].just_released
}

inputs_key_down :: proc(keycode: keycode_e) -> bool {
	return input.keyboard.keys[keycode].is_down
}

inputs_action_down :: proc(action_map: ^input_mapping_t, action_id: i32) -> bool {
    action, ok := action_map.actions[action_id]
    assert(ok, "unregistered action: ")
    for button in action.buttons {
        if button.is_down {return true}
    }
    return false
}


inputs_mouse_button_pressed :: proc(mouse_button: mouse_buttons_e) -> bool {
	return input.mouse.buttons[mouse_button].just_pressed
}

inputs_mouse_button_released :: proc(mouse_button: mouse_buttons_e) -> bool {
	return input.mouse.buttons[mouse_button].just_released
}

inputs_mouse_button_down :: proc(mouse_button: mouse_buttons_e) -> bool {
	return input.mouse.buttons[mouse_button].is_down
}

inputs_action_pressed :: proc(action_map: ^input_mapping_t, action_id: i32) -> bool {
    action, ok := action_map.actions[action_id]
    assert(ok, "unregistered action: ")
    for button in action.buttons {
        if button.just_pressed {return true}
    }
    return false
}


inputs_gamepad_button_pressed :: proc(gamepad_button: gamepad_buttons_e) -> bool {
	return input.gamepad.buttons[gamepad_button].just_pressed
}

inputs_gamepad_button_released :: proc(gamepad_button: gamepad_buttons_e) -> bool {
	return input.gamepad.buttons[gamepad_button].just_released
}

inputs_gamepad_button_down :: proc(gamepad_button: gamepad_buttons_e) -> bool {
	return input.gamepad.buttons[gamepad_button].is_down
}

inputs_action_released :: proc(action_map: ^input_mapping_t, action_id: i32) -> bool {
    action, ok := action_map.actions[action_id]
    assert(ok, "unregistered action: ")
    for button in action.buttons {
        if button.just_released {return true}
    }
    return false
}


inputs_listen_to_glfw_keys :: proc "c" (
	window: glfw.WindowHandle,
	key: c.int,
	scancode, action, mods: c.int,
) {
	is_down: bool = (action == glfw.PRESS || action == glfw.REPEAT)
	keycode := glfw_key_lookup_table[key]
	p_key := &input.keyboard.keys[keycode]

	p_key.just_pressed = !p_key.just_pressed && !p_key.is_down && is_down
	p_key.just_released = !p_key.just_released && p_key.is_down && !is_down
	p_key.is_down = is_down
	p_key.half_transition_count += 1
}

inputs_listen_to_glfw_mouse_buttons :: proc "c" (
	window: glfw.WindowHandle,
	button, action, mods: c.int,
) {
	is_down: bool = (action == glfw.PRESS || action == glfw.REPEAT)
	button_code := glfw_mouse_buttons_lookup_table[button]
	p_button := &input.mouse.buttons[button_code]

	p_button.just_pressed = !p_button.just_pressed && !p_button.is_down && is_down
	p_button.just_released = !p_button.just_released && p_button.is_down && !is_down
	p_button.is_down = is_down
	p_button.half_transition_count += 1
}


inputs_fill_lookup_tables :: proc() {
	glfw_key_lookup_table = map[c.int]keycode_e {
		glfw.KEY_A             = keycode_e.KEY_A,
		glfw.KEY_B             = keycode_e.KEY_B,
		glfw.KEY_C             = keycode_e.KEY_C,
		glfw.KEY_D             = keycode_e.KEY_D,
		glfw.KEY_E             = keycode_e.KEY_E,
		glfw.KEY_F             = keycode_e.KEY_F,
		glfw.KEY_G             = keycode_e.KEY_G,
		glfw.KEY_H             = keycode_e.KEY_H,
		glfw.KEY_I             = keycode_e.KEY_I,
		glfw.KEY_J             = keycode_e.KEY_J,
		glfw.KEY_K             = keycode_e.KEY_K,
		glfw.KEY_L             = keycode_e.KEY_L,
		glfw.KEY_M             = keycode_e.KEY_M,
		glfw.KEY_N             = keycode_e.KEY_N,
		glfw.KEY_O             = keycode_e.KEY_O,
		glfw.KEY_P             = keycode_e.KEY_P,
		glfw.KEY_Q             = keycode_e.KEY_Q,
		glfw.KEY_R             = keycode_e.KEY_R,
		glfw.KEY_S             = keycode_e.KEY_S,
		glfw.KEY_T             = keycode_e.KEY_T,
		glfw.KEY_U             = keycode_e.KEY_U,
		glfw.KEY_V             = keycode_e.KEY_V,
		glfw.KEY_W             = keycode_e.KEY_W,
		glfw.KEY_X             = keycode_e.KEY_X,
		glfw.KEY_Y             = keycode_e.KEY_Y,
		glfw.KEY_Z             = keycode_e.KEY_Z,
		glfw.KEY_0             = keycode_e.KEY_0,
		glfw.KEY_1             = keycode_e.KEY_1,
		glfw.KEY_2             = keycode_e.KEY_2,
		glfw.KEY_3             = keycode_e.KEY_3,
		glfw.KEY_4             = keycode_e.KEY_4,
		glfw.KEY_5             = keycode_e.KEY_5,
		glfw.KEY_6             = keycode_e.KEY_6,
		glfw.KEY_7             = keycode_e.KEY_7,
		glfw.KEY_8             = keycode_e.KEY_8,
		glfw.KEY_9             = keycode_e.KEY_9,
		glfw.KEY_SPACE         = keycode_e.KEY_SPACE,
		glfw.KEY_APOSTROPHE    = keycode_e.KEY_APOSTROPHE,
		glfw.KEY_MINUS         = keycode_e.KEY_MINUS,
		glfw.KEY_EQUAL         = keycode_e.KEY_EQUAL,
		glfw.KEY_LEFT_BRACKET  = keycode_e.KEY_LEFT_BRACKET,
		glfw.KEY_RIGHT_BRACKET = keycode_e.KEY_RIGHT_BRACKET,
		glfw.KEY_SEMICOLON     = keycode_e.KEY_SEMICOLON,
		glfw.KEY_GRAVE_ACCENT  = keycode_e.KEY_QUOTE,
		glfw.KEY_COMMA         = keycode_e.KEY_COMMA,
		glfw.KEY_PERIOD        = keycode_e.KEY_PERIOD,
		glfw.KEY_SLASH         = keycode_e.KEY_FORWARD_SLASH,
		glfw.KEY_BACKSLASH     = keycode_e.KEY_BACKWARD_SLASH,
		glfw.KEY_TAB           = keycode_e.KEY_TAB,
		glfw.KEY_ESCAPE        = keycode_e.KEY_ESCAPE,
		glfw.KEY_PAUSE         = keycode_e.KEY_PAUSE,
		glfw.KEY_UP            = keycode_e.KEY_UP,
		glfw.KEY_DOWN          = keycode_e.KEY_DOWN,
		glfw.KEY_LEFT          = keycode_e.KEY_LEFT,
		glfw.KEY_RIGHT         = keycode_e.KEY_RIGHT,
		glfw.KEY_BACKSPACE     = keycode_e.KEY_BACKSPACE,
		glfw.KEY_INSERT        = keycode_e.KEY_RETURN,
		glfw.KEY_DELETE        = keycode_e.KEY_DELETE,
		glfw.KEY_INSERT        = keycode_e.KEY_INSERT,
		glfw.KEY_HOME          = keycode_e.KEY_HOME,
		glfw.KEY_END           = keycode_e.KEY_END,
		glfw.KEY_PAGE_UP       = keycode_e.KEY_PAGE_UP,
		glfw.KEY_PAGE_DOWN     = keycode_e.KEY_PAGE_DOWN,
		glfw.KEY_CAPS_LOCK     = keycode_e.KEY_CAPS_LOCK,
		glfw.KEY_NUM_LOCK      = keycode_e.KEY_NUM_LOCK,
		glfw.KEY_SCROLL_LOCK   = keycode_e.KEY_SCROLL_LOCK,
		glfw.KEY_MENU          = keycode_e.KEY_MENU,
		glfw.KEY_LEFT_SHIFT    = keycode_e.KEY_LEFT_SHIFT,
		glfw.KEY_RIGHT_SHIFT   = keycode_e.KEY_RIGHT_SHIFT,
		glfw.KEY_LEFT_CONTROL  = keycode_e.KEY_LEFT_CONTROL,
		glfw.KEY_RIGHT_CONTROL = keycode_e.KEY_RIGHT_CONTROL,
		glfw.KEY_LEFT_ALT      = keycode_e.KEY_LEFT_ALT,
		glfw.KEY_RIGHT_ALT     = keycode_e.KEY_RIGHT_ALT,
		glfw.KEY_LEFT_SUPER    = keycode_e.KEY_LEFT_SUPER,
		glfw.KEY_RIGHT_SUPER   = keycode_e.KEY_RIGHT_SUPER,
		glfw.KEY_F1            = keycode_e.KEY_F1,
		glfw.KEY_F2            = keycode_e.KEY_F2,
		glfw.KEY_F3            = keycode_e.KEY_F3,
		glfw.KEY_F4            = keycode_e.KEY_F4,
		glfw.KEY_F5            = keycode_e.KEY_F5,
		glfw.KEY_F6            = keycode_e.KEY_F6,
		glfw.KEY_F7            = keycode_e.KEY_F7,
		glfw.KEY_F8            = keycode_e.KEY_F8,
		glfw.KEY_F9            = keycode_e.KEY_F9,
		glfw.KEY_F10           = keycode_e.KEY_F10,
		glfw.KEY_F11           = keycode_e.KEY_F11,
		glfw.KEY_F12           = keycode_e.KEY_F12,
		glfw.KEY_KP_0          = keycode_e.KEY_NUMPAD_0,
		glfw.KEY_KP_1          = keycode_e.KEY_NUMPAD_1,
		glfw.KEY_KP_2          = keycode_e.KEY_NUMPAD_2,
		glfw.KEY_KP_3          = keycode_e.KEY_NUMPAD_3,
		glfw.KEY_KP_4          = keycode_e.KEY_NUMPAD_4,
		glfw.KEY_KP_5          = keycode_e.KEY_NUMPAD_5,
		glfw.KEY_KP_6          = keycode_e.KEY_NUMPAD_6,
		glfw.KEY_KP_7          = keycode_e.KEY_NUMPAD_7,
		glfw.KEY_KP_8          = keycode_e.KEY_NUMPAD_8,
		glfw.KEY_KP_9          = keycode_e.KEY_NUMPAD_9,
		glfw.KEY_KP_MULTIPLY   = keycode_e.KEY_NUMPAD_STAR,
		glfw.KEY_KP_ADD        = keycode_e.KEY_NUMPAD_PLUS,
		glfw.KEY_KP_SUBTRACT   = keycode_e.KEY_NUMPAD_MINUS,
		glfw.KEY_KP_DIVIDE     = keycode_e.KEY_NUMPAD_SLASH,
		glfw.KEY_KP_ENTER      = keycode_e.KEY_NUMPAD_ENTER,
		glfw.KEY_KP_DECIMAL    = keycode_e.KEY_NUMPAD_DECIMAL,
	}

	glfw_mouse_buttons_lookup_table = map[c.int]mouse_buttons_e {
		glfw.MOUSE_BUTTON_1 = mouse_buttons_e.MOUSE_BUTTON_1,
		glfw.MOUSE_BUTTON_2 = mouse_buttons_e.MOUSE_BUTTON_2,
		glfw.MOUSE_BUTTON_3 = mouse_buttons_e.MOUSE_BUTTON_3,
		glfw.MOUSE_BUTTON_4 = mouse_buttons_e.MOUSE_BUTTON_4,
		glfw.MOUSE_BUTTON_5 = mouse_buttons_e.MOUSE_BUTTON_5,
		glfw.MOUSE_BUTTON_6 = mouse_buttons_e.MOUSE_BUTTON_6,
		glfw.MOUSE_BUTTON_7 = mouse_buttons_e.MOUSE_BUTTON_7,
		glfw.MOUSE_BUTTON_8 = mouse_buttons_e.MOUSE_BUTTON_8,
	}

	glfw_gamepad_buttons_lookup_table = map[c.int]gamepad_buttons_e {
		glfw.GAMEPAD_BUTTON_A            = gamepad_buttons_e.GAMEPAD_BUTTON_A,
		glfw.GAMEPAD_BUTTON_B            = gamepad_buttons_e.GAMEPAD_BUTTON_B,
		glfw.GAMEPAD_BUTTON_X            = gamepad_buttons_e.GAMEPAD_BUTTON_X,
		glfw.GAMEPAD_BUTTON_Y            = gamepad_buttons_e.GAMEPAD_BUTTON_Y,
		glfw.GAMEPAD_BUTTON_DPAD_LEFT    = gamepad_buttons_e.GAMEPAD_BUTTON_DPAD_LEFT,
		glfw.GAMEPAD_BUTTON_DPAD_RIGHT   = gamepad_buttons_e.GAMEPAD_BUTTON_DPAD_RIGHT,
		glfw.GAMEPAD_BUTTON_DPAD_UP      = gamepad_buttons_e.GAMEPAD_BUTTON_DPAD_UP,
		glfw.GAMEPAD_BUTTON_DPAD_DOWN    = gamepad_buttons_e.GAMEPAD_BUTTON_DPAD_DOWN,
		glfw.GAMEPAD_BUTTON_LEFT_THUMB   = gamepad_buttons_e.GAMEPAD_BUTTON_LEFT_TRIGGER,
		glfw.GAMEPAD_BUTTON_RIGHT_THUMB  = gamepad_buttons_e.GAMEPAD_BUTTON_RIGHT_TRIGGER,
		glfw.GAMEPAD_BUTTON_LEFT_BUMPER  = gamepad_buttons_e.GAMEPAD_BUTTON_LEFT_BUMPER,
		glfw.GAMEPAD_BUTTON_RIGHT_BUMPER = gamepad_buttons_e.GAMEPAD_BUTTON_RIGHT_BUMPER,
		glfw.GAMEPAD_BUTTON_BACK         = gamepad_buttons_e.GAMEPAD_BUTTON_BACK,
		glfw.GAMEPAD_BUTTON_START        = gamepad_buttons_e.GAMEPAD_BUTTON_START,
		glfw.GAMEPAD_BUTTON_GUIDE        = gamepad_buttons_e.GAMEPAD_BUTTON_GUIDE,
	}

}
