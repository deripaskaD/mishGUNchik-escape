extends SceneTree

# Извлекает анимации из отдельных FBX в один лёгкий AnimationLibrary-ресурс,
# чтобы в рантайме не грузить дубли мешей. Имена по длине клипа:
#   anim_a.fbx 1.22s → walk, anim_b.fbx 2.00s → idle. (run остаётся в основной модели)
func _init() -> void:
	var lib := AnimationLibrary.new()
	_add(lib, "res://art/models/character/anim_a.fbx", "walk")
	_add(lib, "res://art/models/character/anim_b.fbx", "idle")
	var err := ResourceSaver.save(lib, "res://art/models/character/extra_anims.res")
	print("SAVE err=", err, " anims=", lib.get_animation_list())
	quit()

func _add(lib: AnimationLibrary, path: String, newname: String) -> void:
	var ps: PackedScene = load(path)
	var inst: Node = ps.instantiate()
	var ap: AnimationPlayer = _find_ap(inst)
	if ap == null:
		print(path, " NO AnimationPlayer")
		inst.free()
		return
	var nm: String = ap.get_animation_list()[0]
	var anim: Animation = ap.get_animation(nm).duplicate(true)
	anim.loop_mode = Animation.LOOP_LINEAR
	lib.add_animation(newname, anim)
	print("added '", newname, "' from ", path.get_file(), " (src='", nm, "' len=", anim.length, ")")
	inst.free()

func _find_ap(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var r := _find_ap(c)
		if r != null:
			return r
	return null
