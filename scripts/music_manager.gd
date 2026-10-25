extends Node
# Music manager. Register it as an Autoload named "Music"
# (Project > Project Settings > Globals > Autoload).
#
# Usage from any script:
#   Music.play("menu")      # smooth crossfade to the "menu" track
#   Music.stop()            # fade out to silence
#   Music.duck(true)        # lower the volume (used by the pause menu)
#
# Put the audio files in res://audio/music/ named exactly like the "file" values below
# (menu.ogg, board.ogg, duel.ogg, victory.ogg, defeat.ogg). .mp3 and .wav also work.

const FOLDER := "res://audio/music/"
const EXTENSIONS := ["ogg", "mp3", "wav"]

# "loop": true = repeats forever, false = plays once (victory / defeat jingles)
const TRACKS := {
	"menu":    {"file": "menu",    "loop": true},
	"board":   {"file": "board",   "loop": true},
	"duel":    {"file": "duel",    "loop": true},
	"victory": {"file": "victory", "loop": false},
	"defeat":  {"file": "defeat",  "loop": false},
}

const FADE_TIME := 0.8      # seconds of crossfade between tracks
const DUCK_DB := 8.0        # how much quieter the music gets while the game is paused

var volume_db: float = -6.0   # music volume (0 = full, more negative = quieter)

var players: Array = []       # two players, so one fades in while the other fades out
var active: int = 0
var current: String = ""
var ducked: bool = false
var fade_tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # keeps playing while the game is paused
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.volume_db = -80.0
		add_child(p)
		players.append(p)

func target_db() -> float:
	return volume_db - (DUCK_DB if ducked else 0.0)

func play(track: String, fade: float = FADE_TIME) -> void:
	# Already playing this track: just make sure the volume is back to normal
	if track == current and players[active].playing:
		duck(false)
		return
	var stream: AudioStream = load_stream(track)
	if stream == null:
		stop(fade)
		return
	current = track
	ducked = false
	active = 1 - active
	var incoming: AudioStreamPlayer = players[active]
	incoming.stream = stream
	incoming.volume_db = -80.0
	incoming.play()

	if fade_tween != null:
		fade_tween.kill()
	fade_tween = create_tween().set_parallel(true)
	fade_tween.tween_property(incoming, "volume_db", target_db(), fade)
	for p in players:
		if p != incoming and p.playing:
			fade_tween.tween_property(p, "volume_db", -80.0, fade)
	fade_tween.chain().tween_callback(_stop_inactive)

func stop(fade: float = FADE_TIME) -> void:
	current = ""
	if fade_tween != null:
		fade_tween.kill()
	fade_tween = create_tween().set_parallel(true)
	for p in players:
		if p.playing:
			fade_tween.tween_property(p, "volume_db", -80.0, fade)
	fade_tween.chain().tween_callback(_stop_all)

func duck(enabled: bool) -> void:
	ducked = enabled
	var p: AudioStreamPlayer = players[active]
	if p.playing:
		create_tween().tween_property(p, "volume_db", target_db(), 0.25)

func _stop_inactive() -> void:
	for i in players.size():
		if i != active:
			players[i].stop()

func _stop_all() -> void:
	for p in players:
		p.stop()

func load_stream(track: String) -> AudioStream:
	if not TRACKS.has(track):
		push_warning("Unknown music track: " + track)
		return null
	var info: Dictionary = TRACKS[track]
	for ext in EXTENSIONS:
		var path: String = FOLDER + info["file"] + "." + ext
		if ResourceLoader.exists(path):
			var stream: AudioStream = load(path)
			set_loop(stream, info["loop"])
			return stream
	push_warning("Music file not found: " + FOLDER + info["file"] + " (.ogg / .mp3 / .wav)")
	return null

# Turns looping on or off by code, so you don't need to touch the Import tab
func set_loop(stream: AudioStream, enabled: bool) -> void:
	if stream is AudioStreamOggVorbis:
		stream.loop = enabled
	elif stream is AudioStreamMP3:
		stream.loop = enabled
	elif stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		if enabled:
			var bytes: int = 2 if wav.format == AudioStreamWAV.FORMAT_16_BITS else 1
			if wav.stereo:
				bytes *= 2
			wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
			wav.loop_begin = 0
			wav.loop_end = int(wav.data.size() / float(bytes))
		else:
			wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
