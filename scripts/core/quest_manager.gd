extends RefCounted
## QuestManager — цепочка задач главы (state-machine). Чистая логика.

var tasks: Array = []
var index: int = 0
var _stars: Array = []

func setup(task_list: Array) -> void:
	tasks = task_list
	index = 0
	_stars = []

func has_current() -> bool:
	return index < tasks.size()

func current() -> Dictionary:
	if has_current():
		return tasks[index]
	return {}

func complete_current(stars: int) -> void:
	if has_current():
		_stars.append(clampi(stars, 1, 3))
		index += 1

func all_done() -> bool:
	return index >= tasks.size()

func task_count() -> int:
	return tasks.size()

func done_count() -> int:
	return index

func chapter_stars() -> int:
	if _stars.is_empty():
		return 1
	var sum := 0
	for s in _stars:
		sum += int(s)
	return clampi(int(round(float(sum) / float(_stars.size()))), 1, 3)
