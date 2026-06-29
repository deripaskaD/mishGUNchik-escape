extends Node
## Music — фоновая музыка (зацикленная). Толерантна к отсутствию ассета (no-op).
## Drop-in: res://audio/music/<name>.ogg|wav. Уважает настройку GS.music_on.

const DIR := "res://audio/music/"

var _player: AudioStreamPlayer
var _current := ""

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	_player.volume_db = -10.0
	add_child(_player)
	GS.audio_settings_changed.connect(_apply_settings)

func play(name: String) -> void:
	_current = name
	if not GS.music_on:
		return
	if _player.playing and _player.stream != null:
		return
	var stream := _find(name)
	if stream == null:
		return
	_player.stream = stream
	_player.play()

func _apply_settings() -> void:
	if GS.music_on:
		if _current != "" and not _player.playing:
			play(_current)
	else:
		_player.stop()

func _find(name: String) -> AudioStream:
	for ext in [".ogg", ".wav"]:
		var path: String = DIR + name + ext
		if ResourceLoader.exists(path):
			var res: Variant = load(path)
			if res is AudioStreamWAV:
				# включаем бесшовный цикл на лету
				res.loop_mode = AudioStreamWAV.LOOP_FORWARD
				res.loop_begin = 0
				res.loop_end = res.data.size() / 2   # mono 16-bit -> frames
				return res
			if res is AudioStream:
				return res
	return null

func stop() -> void:
	_current = ""
	_player.stop()
