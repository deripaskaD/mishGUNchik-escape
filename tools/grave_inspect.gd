extends SceneTree
func _init():
	for nm in ["cross-wood","gravestone-cross","gravestone-round"]:
		var p="res://art/models/props/%s.glb"%nm
		if not ResourceLoader.exists(p):
			print(nm," MISSING"); continue
		var inst=load(p).instantiate()
		print("== ",nm," ==")
		_w(inst)
		inst.free()
	quit()
func _w(n):
	if n is MeshInstance3D and n.mesh!=null:
		for s in n.mesh.get_surface_count():
			var m=n.mesh.surface_get_material(s)
			if m is StandardMaterial3D:
				var t=m.albedo_texture
				print("  surf",s," color=",m.albedo_color," tex=",(t.resource_path if t else "NONE")," vtx=",m.vertex_color_use_as_albedo)
			else:
				print("  surf",s," mat=",(m.get_class() if m else "NONE"))
	for c in n.get_children(): _w(c)
