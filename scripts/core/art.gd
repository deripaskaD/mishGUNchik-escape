extends Node
## Art — drop-in загрузчик спрайтов. Логика рендера от него не зависит:
## если есть res://art/<key>.png — используется он, иначе fallback-фигура в _draw.

const DIR := "res://art/"

var _cache: Dictionary = {}

func tex(key: String) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	var t: Texture2D = null
	var path: String = DIR + key + ".png"
	if ResourceLoader.exists(path):
		var res: Variant = load(path)
		if res is Texture2D:
			t = res
	_cache[key] = t
	return t

func has(key: String) -> bool:
	return tex(key) != null

func reload() -> void:
	_cache.clear()
