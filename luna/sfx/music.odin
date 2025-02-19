package luna_sfx

import "../base"
import "core:os"
import "core:strings"

import "shared:odin-al/al"
import "shared:odin-al/alc"

MUSIC_BUFFER_SIZE :: 16384

music_t :: struct {
	play_mode:           music_play_mode_e,
	is_playing, started: bool,
	volume:              f32,
	index:               int,
	source:              u32,
	buffers:             [2]u32,
	file:                os.Handle,
}

music_play_mode_e :: enum {
	SINGLE,
	LOOP,
}

music_init :: proc(path: string, play_mode: music_play_mode_e, audio: ^audio_t) -> ^music_t {
	music := new(music_t)
	music.is_playing = false
	music.play_mode = play_mode
	music.volume = 1

	al.gen_sources(1, &music.source)
	al.gen_buffers(2, &music.buffers[0])
	al.sourcef(
		music.source,
		al.GAIN,
		audio.volumes[.GENERAL] * audio.volumes[.MUSIC] * music.volume,
	)

	err: os.Error
	music.file, err = os.open(path)
	//assert(err != nil, strings.concatenate({"failed to open music file: ", path}))
	_, err = os.seek(music.file, WAV_HEADER_END, os.SEEK_SET)
	//assert(err != nil, strings.concatenate({"issue moving in music file: ", path}))

	music.index, _ = append_elem(&audio.musics, music)

	return music
}

music_deinit :: proc(music: ^music_t, audio: ^audio_t) {
	al.source_stop(music.source)
	al.delete_sources(1, &music.source)
	al.delete_buffers(2, &music.buffers[0])
	os.close(music.file)
	free(music)
}

music_set_volume :: proc(music: ^music_t, audio: ^audio_t, volume: f32) {
	music.volume = volume
	al.sourcef(music.source, al.GAIN, audio.volumes[.GENERAL] * audio.volumes[.MUSIC] * volume)
}

music_play :: proc(music: ^music_t) {
	if music.is_playing {
		return
	}

	if !music.started {
		for buffer in music.buffers {
			if !music_fill_buffer(music, buffer) {
				return
			}
		}
		music.started = true
	}

	al.source_queue_buffers(music.source, 2, &music.buffers[0])
	al.source_play(music.source)

	music.is_playing = true
	return
}

music_stop :: proc(music: ^music_t) {
	al.source_stop(music.source)
	al.source_unqueue_buffers(music.source, 2, &music.buffers[0])
	music.is_playing = false
}

music_reset :: proc(music: ^music_t) {
	os.seek(music.file, WAV_HEADER_END, os.SEEK_SET)
	started = false
}

music_fill_buffer :: proc(music: ^music_t, buffer: u32) -> bool {
	temp_data := new([MUSIC_BUFFER_SIZE]byte)
	defer free(temp_data)

	bytes_read, err := os.read(music.file, temp_data[:])

	if err != nil || bytes_read <= 0 {
		music_reset(music)
		music.is_playing = music.play_mode == .LOOP
		started = music.is_playing
		return music.is_playing
	}

	al.buffer_data(buffer, al.FORMAT_STEREO16, &temp_data[0], auto_cast bytes_read, WAV_FREQUENCY)

	return true
}
