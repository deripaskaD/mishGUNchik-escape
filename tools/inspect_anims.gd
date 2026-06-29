extends SceneTree

# Меряет «энергию» анимации прямо по кейфреймам (без позинга скелета):
# суммарный угловой путь всех rotation-треков + вертикальный размах позиционных треков.
func _init() -> void:
	var paths := [
		"res://art/models/character/mishganchik.fbx",
		"res://art/models/character/anim_a.fbx",
		"res://art/models/character/anim_b.fbx",
	]
	for path in paths:
		var ps: PackedScene = load(path)
		var inst: Node = ps.instantiate()
		var ap: AnimationPlayer = _find_ap(inst)
		var nm: String = ap.get_animation_list()[0]
		var anim: Animation = ap.get_animation(nm)
		var rot_energy := 0.0
		var pos_energy := 0.0
		var max_vbob := 0.0
		for t in anim.get_track_count():
			var tt := anim.track_get_type(t)
			var kc := anim.track_get_key_count(t)
			if kc < 2:
				continue
			if tt == Animation.TYPE_ROTATION_3D:
				var prev: Quaternion = anim.track_get_key_value(t, 0)
				for k in range(1, kc):
					var q: Quaternion = anim.track_get_key_value(t, k)
					rot_energy += absf(prev.angle_to(q))
					prev = q
			elif tt == Animation.TYPE_POSITION_3D:
				var p0: Vector3 = anim.track_get_key_value(t, 0)
				var ymin := p0.y
				var ymax := p0.y
				var prevp: Vector3 = p0
				for k in range(1, kc):
					var p: Vector3 = anim.track_get_key_value(t, k)
					pos_energy += (p - prevp).length()
					ymin = minf(ymin, p.y)
					ymax = maxf(ymax, p.y)
					prevp = p
				max_vbob = maxf(max_vbob, ymax - ymin)
		print("%-22s len=%.2fs tracks=%d ROT_ENERGY=%.2f pos_energy=%.3f vbob=%.4f" % [path.get_file(), anim.length, anim.get_track_count(), rot_energy, pos_energy, max_vbob])
		inst.free()
	quit()

func _find_ap(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var r := _find_ap(c)
		if r != null:
			return r
	return null
