package luna_sfx

import "core:mem"

import "shared:odin-al/al"
import "shared:odin-al/alc"


audio_t :: struct {
	device: alc.Device,
	ctx:    alc.Context,
}

audio_init :: proc() -> audio_t {
	audio := new(audio_t)
	audio.device = alc.open_device(nil)
	assert(device != nil, "failed to open openAL device")

	audio.ctx = alc.create_context(audio.device, nil)
	alc.make_context_current(audio.ctx)
	return audio
}

audio_deinit :: proc(audio: ^audio_t) {
	alc.destroy_context(audio.ctx)
	alc.close_device(audio.device)
	free(audio)
	audio = nil
}
