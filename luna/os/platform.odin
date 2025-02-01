package luna_os

running: bool = false

platform_state_t :: union {
	win_platform_state_t,
}

platform_state: platform_state_t

platform_create_window :: proc {
	win_create_window,
}

platform_update_window :: proc {
	win_update_window,
}
