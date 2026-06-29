extends "res://scripts/core/minigame_base.gd"
## Tea — удержание: наполни кружку и отпусти в зелёной зоне.

var _fill: float = 0.0
var _holding: bool = false

func reset() -> void:
	super()
	_fill = 0.0
	_holding = false

func update(delta: float) -> void:
	super(delta)
	if _done:
		return
	if _holding:
		_fill += float(cfg.get("fill_speed", 0.55)) * delta
		if _fill > 1.2:
			# перелив — промах, сброс
			_mistakes += 1
			_fill = 0.0
			_holding = false

func input_press(down: bool) -> void:
	if _done:
		return
	if down:
		_holding = true
	else:
		var target: float = float(cfg.get("target", 0.8))
		var band: float = float(cfg.get("band", 0.1))
		if absf(_fill - target) <= band:
			_finish()
		else:
			_mistakes += 1
			_fill = 0.0
		_holding = false

func progress() -> float:
	if _done:
		return 1.0
	return clampf(_fill, 0.0, 1.0)

func prompt() -> String:
	return "Удерживай и отпусти в зелёной зоне"

func controls() -> Array:
	return ["hold"]

func meta() -> Dictionary:
	return {"target": float(cfg.get("target", 0.8)), "band": float(cfg.get("band", 0.1))}
