extends Node
## Sfx — простой проигрыватель коротких звуков.
## Толерантен к отсутствию ассетов: если файла нет — тихий no-op (игра не падает).
## Файлы (опционально, drop-in): res://audio/sfx/<name>.wav|ogg

const DIR := "res://audio/sfx/"
const POOL := 6

var _players: Array[AudioStreamPlayer] = []
var _idx := 0
var _cache: Dictionary = {}   # name -> AudioStream|null

func _ready() -> void:
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)

func play(name: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not GS.sfx_on:
		return
	var stream := _load(name)
	if stream == null:
		return
	var p := _players[_idx]
	_idx = (_idx + 1) % _players.size()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()

func _load(name: String) -> AudioStream:
	if _cache.has(name):
		return _cache[name]
	var stream: AudioStream = null
	for ext in [".ogg", ".wav"]:
		var path: String = DIR + name + ext
		if ResourceLoader.exists(path):
			var res: Variant = load(path)
			if res is AudioStream:
				stream = res
				break
	_cache[name] = stream
	return stream
