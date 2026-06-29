extends SceneTree

var _white := 0
var _tex := 0
var _tot := 0

func _init() -> void:
	var dir := DirAccess.open("res://art/models/props")
	if dir == null:
		print("no dir")
		quit()
		return
	for f in dir.get_files():
		if not f.ends_with(".glb"):
			continue
		var inst: Node = load("res://art/models/props/" + f).instantiate()
		_white = 0
		_tex = 0
		_tot = 0
		_w(inst)
		if _white > 0:
			print("%-26s surfaces=%d WHITE_NOTEX=%d textured=%d" % [f, _tot, _white, _tex])
		inst.free()
	print("--- done (только белые без текстур) ---")
	quit()

func _w(n: Node) -> void:
	if n is MeshInstance3D and n.mesh != null:
		for s in n.mesh.get_surface_count():
			_tot += 1
			var m: Material = n.mesh.surface_get_material(s)
			if m is StandardMaterial3D:
				var sm: StandardMaterial3D = m
				if sm.albedo_texture != null:
					_tex += 1
				elif sm.albedo_color.r > 0.95 and sm.albedo_color.g > 0.95 and sm.albedo_color.b > 0.95:
					_white += 1
	for c in n.get_children():
		_w(c)
