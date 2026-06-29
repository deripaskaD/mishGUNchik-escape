extends "res://scripts/core/minigame_base.gd"
## Wood — чередование ← →: коли дрова.

var _expect: int = -1   # -1 = сначала левый удар
var _chops: int = 0

func reset() -> void:
	super()
	_expect = -1
	_chops = 0

func input_dir(dir: int) -> void:
	if _done:
		return
	if dir == _expect:
		_chops += 1
		_expect = -_expect
		var target: int = int(cfg.get("target_chops", 10))
		_progress = float(_chops) / float(max(1, target))
		if _chops >= target:
			_finish()
	else:
		_mistakes += 1

func prompt() -> String:
	return "Чередуй ← и → — коли дрова!"

func controls() -> Array:
	return ["L", "R"]

func meta() -> Dictionary:
	return {"expect": _expect}
