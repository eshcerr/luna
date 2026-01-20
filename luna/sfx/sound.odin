package luna_sfx

import "core:os"
import "core:strings"

import "shared:odin-al/al"
import "shared:odin-al/alc"

sound_t :: struct {
	volume:         f32,
	source, buffer: u32,
	index:          int,
}

sound_init :: proc(path: string, audio: ^audio_t) -> ^sound_t {
	content, success := os.read_entire_file(path)
	assert(success, strings.concatenate({"failed to load sound file: ", path}))

	sound := new(sound_t)
	sound.volume = 1

	al.gen_buffers(1, &sound.buffer)
	al.gen_sources(1, &sound.source)

	sound_data := content[WAV_HEADER_END:]
	sound_size := len(sound_data) - (len(sound_data) % 4)

	al.buffer_data(
		sound.buffer,
		al.FORMAT_STEREO16,
		&sound_data[0],
		i32(sound_size),
		WAV_FREQUENCY,
	)

	al.sourcei(sound.source, al.BUFFER, i32(sound.buffer))
	al.sourcef(
		sound.source,
		al.GAIN,
		audio.volumes[.GLOBAL] * audio.volumes[.SOUND] * sound.volume,
	)

	sound.index, _ = append_elem(&audio.sounds, sound)
	return sound
}

sound_deinit :: proc(sound: ^sound_t, audio: ^audio_t) {
	al.source_stop(sound.source)
	al.delete_buffers(1, &sound.buffer)
	al.delete_sources(1, &sound.source)

	unordered_remove(&audio.sounds, sound.index - 1)
	free(sound)
}

sound_set_volume :: proc(sound: ^sound_t, audio: ^audio_t, volume: f32) {
	sound.volume = volume
	al.sourcef(sound.source, al.GAIN, audio.volumes[.GLOBAL] * audio.volumes[.SOUND] * volume)
}

sound_play :: proc(sound: ^sound_t) {
	al.source_stop(sound.source)
	al.sourcei(sound.source, al.BUFFER, i32(sound.buffer))
	al.sourcef(sound.source, al.SEC_OFFSET, 0)
	al.source_play(sound.source)
}
