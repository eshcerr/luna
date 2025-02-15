package luna_sfx

import "../base"
import "core:strings"

import "shared:odin-al/al"
import "shared:odin-al/alc"

sound_t :: struct {
	source, buffer: u32,
	index:          int,
}

sound_load :: proc(filename: string, audio: ^audio_t) -> ^sound_t {
	sound := new(sound_t)
	al.gen_buffers(1, &sound.buffer)
	al.gen_sources(1, &sound.source)

	format: i32
	data: []u8
	frequency: i32

	success := load_wav_file(filename, &format, &data, &frequency)
	assert(success, strings.concatenate({"failed to load sound: ", filename}))
	al.buffer_data(sound.buffer, format, &data[0], i32(len(data)), frequency)
	al.sourcei(sound.source, al.BUFFER, i32(sound.buffer))
	al.sourcef(sound.source, al.GAIN, audio.volumes[.GENERAL] * audio.volumes[.SOUND])

	sound.index, _ = append(&audio.sounds, sound)
	return sound
}

sound_play :: proc(sound: ^sound_t) {
	al.source_play(sound.source)
}

sound_deinit :: proc(sound: ^sound_t, audio: ^audio_t) {
	al.delete_sources(1, &sound.source)
	al.delete_buffers(1, &sound.buffer)

	unordered_remove(&audio.sounds, sound.index - 1)
	free(sound)
}
