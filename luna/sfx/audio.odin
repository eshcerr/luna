package luna_sfx

import "core:math"
import "core:mem"
import "core:os"
import "core:strings"

import "shared:odin-al/al"
import "shared:odin-al/alc"

audio_t :: struct {
	device:  alc.Device,
	ctx:     alc.Context,
	sounds:  [dynamic]^sound_t,
	musics:  [dynamic]^music_t,
	volumes: [audio_volume_type_e]f32,
}

audio_volume_type_e :: enum {
	GENERAL,
	SOUND,
	MUSIC,
}

audio_init :: proc() -> ^audio_t {
	audio := new(audio_t)
	audio.device = alc.open_device(nil)
	assert(audio.device != nil, "failed to open openAL device")

	audio.ctx = alc.create_context(audio.device, nil)
	alc.make_context_current(audio.ctx)

	audio.volumes[.GENERAL] = 0.5
	audio.volumes[.SOUND] = 0.5
	audio.volumes[.MUSIC] = 0.5
	return audio
}

audio_deinit :: proc(audio: ^audio_t) {
	alc.destroy_context(audio.ctx)
	alc.close_device(audio.device)

	for sound in audio.sounds {
		sound_deinit(sound, audio)
	}
	clear_dynamic_array(&audio.sounds)

	for music in audio.musics {
		//music_deinit(music)
	}
	clear_dynamic_array(&audio.musics)

	free(audio)
}

audio_set_volume :: proc(audio: ^audio_t, audio_volume_type: audio_volume_type_e, volume: f32) {
	audio.volumes[audio_volume_type] = math.clamp(volume, 0.0, 1.0) // Ensure volume is between 0.0 and 1.0

	switch audio_volume_type {
	case .SOUND:
		for sound in audio.sounds {
			al.sourcef(sound.source, al.GAIN, audio.volumes[.GENERAL] * audio.volumes[.SOUND])
		}
	case .MUSIC:
		audio_set_musics_volume(audio, volume)

	case .GENERAL:
		{
			// General volume for both SOUND and MUSIC
			for sound in audio.sounds {
				al.sourcef(sound.source, al.GAIN, audio.volumes[.GENERAL] * audio.volumes[.SOUND])
			}
			audio_set_musics_volume(audio, volume)
		}
	}
}

audio_set_musics_volume :: proc(audio: ^audio_t, volume: f32) {
	for music in audio.musics {
		switch music.music_type {
		case .STREAMING:
			al.sourcef(
				music.music.(^music_streaming_t).source,
				al.GAIN,
				audio.volumes[.GENERAL] * audio.volumes[.MUSIC],
			)

		case .LAYERED:
			for layer in music.music.(^music_layered_t).layers {
				al.sourcef(
					layer.music.source,
					al.GAIN,
					audio.volumes[.GENERAL] * audio.volumes[.MUSIC] * layer.volume,
				)
			}
		}
	}
}

audio_update_musics :: proc (audio: ^audio_t) {
	for music in audio.musics {
		music_update(music)
	}
}

load_wav_file :: proc(filename: string, format: ^i32, data: ^[]u8, freq: ^i32) -> bool {
	content, success := os.read_entire_file(filename)
	assert(success, strings.concatenate({"failed to read WAV file: ", filename}))

	switch content[22] {
	case 1:
		if content[34] == 16 {format^ = al.FORMAT_MONO16} else {format^ = al.FORMAT_MONO8}
	case:
		if content[34] == 16 {format^ = al.FORMAT_STEREO16} else {format^ = al.FORMAT_STEREO8}
	}

	freq^ = unpack_le_u32(content[24:28])
	data^ = content[44:] // Skip WAV header

	return true
}

unpack_le_u32 :: proc(bytes: []u8) -> i32 {
	return i32(bytes[0]) | (i32(bytes[1]) << 8) | (i32(bytes[2]) << 16) | (i32(bytes[3]) << 24)
}
