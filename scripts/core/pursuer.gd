extends RefCounted
## Pursuer — логика преследователя (шалуна). Чистая, тестируемая.
## update() двигает к цели; периодически телеграфирует и совершает рывок.

var pos: Vector2 = Vector2.ZERO
var speed: float = 240.0
var dash_speed: float = 520.0
var telegraph_time: float = 0.55
var dash_time: float = 0.35
var lunge_interval: float = 3.6
var lunge_range: float = 540.0
var slow_factor: float = 0.38
var radius: float = 30.0

var phase: String = "walk"   # walk | telegraph | dash | frozen

var _telegraphing: bool = false
var _t_tele: float = 0.0
var _dashing: bool = false
var _t_dash: float = 0.0
var _cd: float = 0.0

func configure(t: Dictionary) -> void:
	speed = float(t.get("pursuer_speed", speed))
	dash_speed = float(t.get("dash_speed", dash_speed))
	telegraph_time = float(t.get("telegraph_time", telegraph_time))
	dash_time = float(t.get("dash_time", dash_time))
	lunge_interval = float(t.get("lunge_interval", lunge_interval))
	lunge_range = float(t.get("lunge_range", lunge_range))
	slow_factor = float(t.get("slow_factor", slow_factor))
	radius = float(t.get("pursuer_r", radius))
	_cd = lunge_interval

func update(delta: float, target: Vector2, slowed: bool, frozen: bool) -> void:
	if frozen:
		phase = "frozen"
		return
	# машина рывка (подавлена у замедляющей зоны)
	if not _telegraphing and not _dashing:
		_cd -= delta
		if _cd <= 0.0 and not slowed and pos.distance_to(target) < lunge_range:
			_telegraphing = true
			_t_tele = telegraph_time
	elif _telegraphing:
		_t_tele -= delta
		if _t_tele <= 0.0:
			_telegraphing = false
			_dashing = true
			_t_dash = dash_time
	elif _dashing:
		_t_dash -= delta
		if _t_dash <= 0.0:
			_dashing = false
			_cd = lunge_interval

	var spd := speed
	if _dashing:
		spd = dash_speed
		phase = "dash"
	elif _telegraphing:
		spd *= 0.15
		phase = "telegraph"
	else:
		phase = "walk"
	if slowed:
		spd *= slow_factor

	var dir := target - pos
	if dir.length() > 1.0:
		pos += dir.normalized() * spd * delta

func on_catch() -> void:
	_telegraphing = false
	_dashing = false
	_cd = lunge_interval
	phase = "walk"

func distance_to(p: Vector2) -> float:
	return pos.distance_to(p)
