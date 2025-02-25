package luna_gfx

import "../base"

animation_option_e :: enum {
	LOOP,
	ONE_TIME,
}

animation_play_state_e :: enum {
	STOPED,
	PLAYING,
	PAUSED,
}

animation_t :: struct {
	option:     animation_option_e,
	play_state: animation_play_state_e,
	state:      animation_state_t,
	frames:     []animation_frame_t,
}

animation_state_t :: struct {
	time, next_frame_time: f32,
	current_frame_index:   u32,
}

animation_frame_t :: struct {
	duration:   f32,
	atlas_rect: u32,
	offset: base.ivec2,
}

animation_get_frame_rect :: proc(animation: ^animation_t) -> u32 {
	return animation.frames[animation.state.current_frame_index].atlas_rect
}

animation_current_frame :: proc(animation: ^animation_t) -> animation_frame_t {
	return animation.frames[animation.state.current_frame_index]
}

animation_deinit :: proc(animation: ^animation_t) {
	free(&animation.frames)
}

animation_start :: proc(animation: ^animation_t) {
	animation.play_state = .PLAYING
	animation.state.current_frame_index = 0
	animation.state.time = 0
	animation.state.next_frame_time = animation.frames[0].duration
}

animation_stop :: proc(animation: ^animation_t) {
	animation.play_state = .STOPED
}

animation_pause :: proc(animation: ^animation_t) {
	animation.play_state = .PAUSED
}

animation_resume :: proc(animation: ^animation_t) {
	animation.play_state = .PLAYING
}


animation_update :: proc(a: ^animation_t, delta_time: f32) {
	if a.play_state == .STOPED || a.play_state == .PAUSED {return}

	a.state.time += delta_time
	if a.state.time >= a.state.next_frame_time {
		//base.log_info(a.state.current_frame_index, animation_get_frame_rect(a))
		if a.state.current_frame_index + 1 >= u32(len(a.frames)) {
			if a.option == .ONE_TIME {
				a.play_state = .STOPED
			} else if a.option == .LOOP {
				a.state.current_frame_index = 0
				a.state.time -= a.state.next_frame_time
				a.state.next_frame_time = a.frames[0].duration
			}
		} else {
			a.state.current_frame_index += 1
			a.state.next_frame_time += a.frames[a.state.current_frame_index].duration
		}
	}
}
