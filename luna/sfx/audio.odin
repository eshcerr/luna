package luna_sfx

import "core:math"
import "core:mem"
import "core:os"
import "core:strings"

import "shared:odin-al/al"
import "shared:odin-al/alc"

WAV_HEADER_END :: 44
WAV_FREQUENCY :: 44100

audio_t :: struct {
	device:  alc.Device,
	ctx:     alc.Context,
	sounds:  [dynamic]^sound_t,
	musics:  [dynamic]^music_t,
	volumes: [audio_volume_type_e]f32,
}

audio: ^audio_t

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
		music_deinit(music, audio)
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
		al.sourcef(music.source, al.GAIN, audio.volumes[.GENERAL] * audio.volumes[.MUSIC])
	}
}

audio_update_musics :: proc(audio: ^audio_t) {
	processed_buffers, state: i32
	buffer: u32

	for music in audio.musics {
		if !music.is_playing {
			continue
		}

		al.get_sourcei(music.source, al.BUFFERS_PROCESSED, &processed_buffers)

		for processed_buffers > 0 {
			al.source_unqueue_buffers(music.source, 1, &buffer)

			if music_fill_buffer(music, buffer) {
				al.source_queue_buffers(music.source, 1, &buffer)
			}

			processed_buffers -= 1
		}

		al.get_sourcei(music.source, al.SOURCE_STATE, &state)
		if state != al.PLAYING {
			al.source_play(music.source)
		}
	}
}
