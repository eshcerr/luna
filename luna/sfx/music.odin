package luna_sfx

import "shared:odin-al/al"
import "shared:odin-al/alc"

import "core:os"

music_t :: struct {
	music_type: music_type_e,
	mode:       music_mode_e,
	is_playing: bool,
	index:      int,
	music:      union {
		^music_streaming_t,
		^music_layered_t,
	},
}

music_type_e :: enum {
	STREAMING,
	LAYERED,
}

music_mode_e :: enum {
	SINGLE,
	LOOP,
}

music_streaming_t :: struct {
	source:  u32,
	buffers: [2]u32,
	file:    os.Handle,
}

music_layered_t :: struct {
	layers: [dynamic]music_layer_t,
}

music_layer_t :: struct {
	music:  ^music_streaming_t,
	volume: f32,
}

music_init :: proc {
	music_init_streaming,
	music_init_layered,
}

music_init_streaming :: proc(audio: ^audio_t, path: string) -> ^music_t {
	music := new(music_t)
	music.music_type = .STREAMING
	music.is_playing = false
	music.music = new(music_streaming_t)
	music.mode = .LOOP

	music.music.(^music_streaming_t).file, _ = os.open(path)

	music_init_streaming_buffers(music.music.(^music_streaming_t), audio)
	music.index, _ = append_elem(&audio.musics, music)

	return music
}

music_init_layered :: proc(audio: ^audio_t, paths: []string) -> ^music_t {
	music := new(music_t)
	music.music_type = .LAYERED
	music.is_playing = false
	music.music = new(music_layered_t)

	//music_init_streaming_buffers(&music.music)
	return music
}

music_init_streaming_buffers :: proc(music: ^music_streaming_t, audio: ^audio_t) {
	al.gen_sources(1, &music.source)
	al.gen_buffers(2, &music.buffers[0])
	al.sourcef(music.source, al.GAIN, audio.volumes[.GENERAL] * audio.volumes[.MUSIC])
}

music_play :: proc(music: ^music_t) {
	if music.is_playing {
		return
	}

	switch music.music_type {
	case .STREAMING:
		@(static) streaming: ^music_streaming_t
		streaming = music.music.(^music_streaming_t)

		// Fill buffers before starting playback
		for buffer in streaming.buffers {
			if !music_fill_buffer(music, buffer, streaming) {
				return // Failed to fill buffer
			}
		}

		al.source_queue_buffers(streaming.source, 2, &streaming.buffers[0])
		al.source_play(streaming.source)
		music.is_playing = true

	case .LAYERED:
		for layer in music.music.(^music_layered_t).layers {
			al.source_queue_buffers(layer.music.source, 2, &layer.music.buffers[0])
			al.source_play(layer.music.source)
			music.is_playing = true
		}
	}
}

music_update :: proc(music: ^music_t) {
	switch music.music_type {
	case .STREAMING:
		music_update_streaming(music, music.music.(^music_streaming_t))
	case .LAYERED:
		for layer in music.music.(^music_layered_t).layers {
			music_update_streaming(music, layer.music)
		}
	}
}

music_update_streaming :: proc(music: ^music_t, streaming: ^music_streaming_t) {
	processed_buffers: i32
	al.get_sourcei(streaming.source, al.BUFFERS_PROCESSED, &processed_buffers)

	for processed_buffers > 0 {
		buffer: u32
		al.source_unqueue_buffers(streaming.source, 1, &buffer)

		// Fill the buffer with new audio data from the file
		if music_fill_buffer(music, buffer, streaming) {
			al.source_queue_buffers(streaming.source, 1, &buffer)
		}

		processed_buffers -= 1
	}

	// Restart playback if it stopped
	state: i32
	al.get_sourcei(streaming.source, al.SOURCE_STATE, &state)
	if state != al.PLAYING {
		al.source_play(streaming.source)
	}
}

music_fill_buffer :: proc(music: ^music_t, buffer: u32, streaming: ^music_streaming_t) -> bool {
	// Define the chunk size to read per buffer (e.g., 4096 samples per buffer)
	BUFFER_SIZE :: 16384 * 2
	temp_data := new([BUFFER_SIZE]byte) // Temporary buffer
	defer free(temp_data)

	// Read audio data from the file
	bytes_read, err := os.read(streaming.file, temp_data[:])
	if err != nil || bytes_read <= 0 {
		// End of file reached, return false to stop queuing new buffers
		os.seek(streaming.file, 44, os.SEEK_SET)
		if music.mode == .LOOP {
			music.is_playing = true
			return true
		}
		else if music.mode == .SINGLE {
			music.is_playing = false
			return false
		}
		return false
	}

	// Fill OpenAL buffer with new audio data
	al.buffer_data(buffer, al.FORMAT_STEREO16, &temp_data[0], auto_cast bytes_read, 44100) // Assuming 44.1kHz stereo

	return true
}

music_deinit :: proc(music: ^music_t, audio: ^audio_t) {
	switch music.music_type {
	case .STREAMING:
		music_deinit_streaming(music.music.(^music_streaming_t))
	case .LAYERED:
		music_deinit_layered(music.music.(^music_layered_t))
	}
	unordered_remove(&audio.musics, music.index - 1)
	free(music)
}

music_deinit_layered :: proc(music: ^music_layered_t) {
	for layer in music.layers {
		music_deinit_streaming(layer.music)
	}
	free(music)
}

music_deinit_streaming :: proc(music: ^music_streaming_t) {
	al.delete_sources(1, &music.source)
	al.delete_buffers(2, &music.buffers[0])
	os.close(music.file)
	free(music)
}
