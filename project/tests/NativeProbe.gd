extends SceneTree
func _initialize():
	ProjectSettings.load_resource_pack(OS.get_cmdline_user_args()[0],false)
	for path in ["res://Scenes/Village.scn","res://Prefabs/Village/Cabin_Area.tscn","res://Effects/Hit_Default.tscn"]:
		var scene=load(path) as PackedScene
		if not scene:continue
		var state=scene.get_state()
		for i in state.get_node_count():
			var instance=state.get_node_instance(i)
			if "Cabin" in str(state.get_node_name(i)) or path.contains("Hit_Default"):
				var props={}
				for j in state.get_node_property_count(i):
					var key=str(state.get_node_property_name(i,j))
					if key in ["transform","collision_mask","script"]:props[key]=str(state.get_node_property_value(i,j))
				print(path," ",state.get_node_path(i)," instance=",instance.resource_path if instance else ""," ",props)
	quit()
