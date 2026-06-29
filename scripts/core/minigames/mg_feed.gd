extends "res://scripts/core/minigame_base.gd"
## Feed — тайминг: метка бегает по полосе, тапай в зелёной зоне, чтобы накормить шалуна.

var _m: float = 0.0       # позиция метки 0..1
var _dir: float = 1.0
var _hits: int = 0

func reset() -> void:
	super()
	_m = 0.0
	_dir = 1.0
	_hits = 0

func update(delta: float) -> void:
	super(delta)
	if _done:
		return
	var spd: float = float(cfg.get("marker_speed", 0.9))
	_m += _dir * spd * delta
	if _m >= 1.0:
		_m = 1.0
		_dir = -1.0
	elif _m <= 0.0:
		_m = 0.0
		_dir = 1.0

func input_tap() -> void:
	if _done:
		return
	var t: float = float(cfg.get("target", 0.5))
	var b: float = float(cfg.get("band", 0.13))
	if absf(_m - t) <= b:
		_hits += 1
		var need: int = int(cfg.get("target_hits", 5))
		_progress = float(_hits) / float(max(1, need))
		if _hits >= need:
			_finish()
	else:
		_mistakes += 1

func prompt() -> String:
	return "Накорми шалуна — тапай, когда метка в зелёной зоне!"

func controls() -> Array:
	return ["tap"]

func meta() -> Dictionary:
	return {"marker": _m, "target": float(cfg.get("target", 0.5)), "band": float(cfg.get("band", 0.13)), "timing": true}
