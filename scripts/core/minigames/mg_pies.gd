extends "res://scripts/core/minigame_base.gd"
## Pies — мэш-тапы: лепи пирожки.

func input_tap() -> void:
	if _done:
		return
	var target: int = int(cfg.get("target_taps", 13))
	_progress += 1.0 / float(max(1, target))
	if _progress >= 1.0:
		_finish()

func prompt() -> String:
	return "Тапай — лепи пирожки!"

func controls() -> Array:
	return ["tap"]
