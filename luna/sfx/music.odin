package luna_sfx

import "shared:odin-al/al"
import "shared:odin-al/alc"

music_t :: struct {
	source:     u32,
	buffer:     [2]u32, // Double-buffering for streaming
	is_playing: bool,
}

music_load :: proc(filename: string, audio: ^audio_t) -> ^music_t {
	music := new(music_t)
	al.gen_sources(1, &music.source)
	al.gen_buffers(2, &music.buffer[0])
	al.sourcef(music.source, al.GAIN, audio.volumes[.GENERAL] * audio.volumes[.MUSIC])

	// Load and queue first buffer (TODO: Implement streaming later)
	return music
}

music_play :: proc(music: ^music_t) {
    if music.is_playing {
        return
    }
    al.source_queue_buffers(music.source, 2, &music.buffers[0])
    al.source_play(music.source)
}

music_destroy :: proc(music: ^music_t) {
	al.delete_sources(1, &music.source)
	al.delete_buffers(2, &music.buffer[0])
	free(music)
}
