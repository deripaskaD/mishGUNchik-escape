extends RefCounted
## MinigameBase — общий интерфейс короткой мини-игры (ADR-0003).
## Наследники переопределяют ввод/прогресс/подсказку. Звёзды считает базовый класс.

var cfg: Dictionary = {}
var _progress: float = 0.0
var _done: bool = false
var _time: float = 0.0
var _mistakes: int = 0

func setup(c: Dictionary) -> void:
	cfg = c
	reset()

func reset() -> void:
	_progress = 0.0
	_done = false
	_time = 0.0
	_mistakes = 0

func update(delta: float) -> void:
	if not _done:
		_time += delta

# --- Ввод (наследники переопределяют нужное) ---
func input_tap() -> void:
	pass

func input_press(_down: bool) -> void:
	pass

func input_dir(_dir: int) -> void:
	pass

# --- Чтение состояния ---
func progress() -> float:
	return clampf(_progress, 0.0, 1.0)

func is_done() -> bool:
	return _done

func stars() -> int:
	var par: float = float(cfg.get("par_time", 6.0))
	if _time <= par and _mistakes == 0:
		return 3
	if _time <= par * 1.6 and _mistakes <= 2:
		return 2
	return 1

func mistakes() -> int:
	return _mistakes

func prompt() -> String:
	return "Действуй!"

# Контекстные кнопки/ввод: ["tap"], ["hold"] или ["L","R"]
func controls() -> Array:
	return ["tap"]

# Доп. подсказки для отрисовки (напр. целевая зона для tea)
func meta() -> Dictionary:
	return {}

func _finish() -> void:
	_progress = 1.0
	_done = true
