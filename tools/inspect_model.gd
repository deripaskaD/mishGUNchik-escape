extends SceneTree

func _init() -> void:
	var path := "res://art/models/character/mishganchik.fbx"
	var ps: PackedScene = load(path)
	if ps == null:
		print("LOAD FAILED: ", path)
		quit()
		return
	var root: Node = ps.instantiate()
	print("=== ROOT: ", root.name, " (", root.get_class(), ") ===")
	_walk(root, 0)
	print("=== ANIMATIONS ===")
	_find_anims(root)
	print("=== BOUNDS ===")
	var aabb := _combined_aabb(root)
	print("AABB pos=", aabb.position, " size=", aabb.size, " (height=", aabb.size.y, ")")
	print("=== MATERIALS ===")
	_find_mats(root)
	quit()

func _walk(n: Node, d: int) -> void:
	var pad := ""
	for i in d:
		pad += "  "
	var extra := ""
	if n is MeshInstance3D and n.mesh != null:
		extra = " mesh_surfaces=" + str(n.mesh.get_surface_count())
	print(pad, "- ", n.name, " [", n.get_class(), "]", extra)
	for c in n.get_children():
		_walk(c, d + 1)

func _find_anims(n: Node) -> void:
	if n is AnimationPlayer:
		print("AnimationPlayer: ", n.get_path())
		for a in n.get_animation_list():
			var anim: Animation = n.get_animation(a)
			print("   anim '", a, "' len=", anim.length, " loop=", anim.loop_mode)
	for c in n.get_children():
		_find_anims(c)

func _combined_aabb(n: Node) -> AABB:
	var result := AABB()
	var first := true
	for mi in _all_meshes(n):
		var ab: AABB = mi.get_aabb()
		# transform into root space (approx via global-ish: use mesh aabb scaled by node transform)
		var t: Transform3D = mi.transform
		var p: Node = mi.get_parent()
		while p != null and p is Node3D:
			t = p.transform * t
			p = p.get_parent()
		ab = t * ab
		if first:
			result = ab
			first = false
		else:
			result = result.merge(ab)
	return result

func _all_meshes(n: Node) -> Array:
	var out: Array = []
	if n is MeshInstance3D and n.mesh != null:
		out.append(n)
	for c in n.get_children():
		out += _all_meshes(c)
	return out

func _find_mats(n: Node) -> void:
	if n is MeshInstance3D and n.mesh != null:
		for s in n.mesh.get_surface_count():
			var m: Material = n.mesh.surface_get_material(s)
			var om: Material = n.get_surface_override_material(s)
			var use: Material = om if om != null else m
			if use is StandardMaterial3D:
				var sm: StandardMaterial3D = use
				var tex := sm.albedo_texture
				print(n.name, " surf", s, " albedo_tex=", (tex.resource_path if tex != null else "NONE"), " color=", sm.albedo_color)
			elif use != null:
				print(n.name, " surf", s, " mat=", use.get_class())
			else:
				print(n.name, " surf", s, " mat=NONE")
	for c in n.get_children():
		_find_mats(c)
