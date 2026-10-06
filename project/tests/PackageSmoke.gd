extends SceneTree
func _initialize() -> void:run.call_deferred()
func run() -> void:
	var archives=OS.get_cmdline_user_args()
	if archives.is_empty() or not ProjectSettings.load_resource_pack(archives[0],true):quit(1);return
	if not FileAccess.file_exists("res://mods/ShootingRange/Main.gd"):push_error("Pack missing Main");quit(1);return
	var script=load("res://mods/ShootingRange/Main.gd")
	if not script or not script.can_instantiate():quit(1);return
	for kind in load("res://mods/ShootingRange/Catalog.gd").TYPES:
		var target=load("res://mods/ShootingRange/Target.gd").new()
		target.kind=kind
		root.add_child(target)
		if target.bodies.is_empty():quit(1);return
		target.free()
	print("RANGE_PACKAGE_SMOKE_COMPLETE all twelve types loaded from VMZ")
	quit()
