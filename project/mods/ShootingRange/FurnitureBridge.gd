extends Node
const Catalog=preload("res://mods/ShootingRange/Catalog.gd")
const Target=preload("res://mods/ShootingRange/Target.gd")
const DIR="res://Assets/ShootingRange/"
var host: Node
var lib: Node
var hooks: Array[int]=[]
var registered=false
var shot_depth=0
var saved_groups: Array[Node]=[]
func _ready() -> void:
	if not Engine.has_meta("RTVModLib"):return
	lib=Engine.get_meta("RTVModLib")
	hooks.append(lib.hook("interface-contextplace-pre",before_place))
	hooks.append(lib.hook("weaponrig-raycast-pre",before_shot))
	hooks.append(lib.hook("weaponrig-raycast-post",after_shot))
	Engine.set_meta("RangeShotFilter",not hooks.has(-1))
	hooks.append(lib.hook("loader-saveshelter-pre",before_save))
	hooks.append(lib.hook("loader-saveshelter-post",after_save))
	hooks.append(lib.hook("trader-filltraderbucket-post",fill_trader))
	register_items.call_deferred()
func register_items() -> void:
	var entries={}
	for kind in Catalog.TYPES:
		entries["ShootingRange_"+kind]={"item_path":DIR+kind+"_F.tres","scene_path":DIR+kind+"_F.tscn","icon_path":"res://mods/ShootingRange/assets/icon_"+kind+".png","trader_pools":["Generalist"]}
	var result=lib.register_furniture(entries)
	registered=bool(result.get("ok",false))
	if not registered:print("[ShootingRange] registration details=",result)
	print("[ShootingRange] furniture registration=",registered," designs=",entries.size())
	# Cheat Menu's eager startup scan can precede our deferred registration.
	# Refresh once after publishing the bundles; do not grant catalog items.
	var spawner=get_node_or_null("/root/CheatMenuMain")
	if registered and spawner and spawner.has_method("_scan_catalog"):
		spawner.call_deferred("_scan_catalog")
func create(kind: String) -> Node3D:
	if ResourceLoader.exists("res://Scripts/Furniture.gd") and ResourceLoader.exists(DIR+kind+"_F.tscn"):
		return load(DIR+kind+"_F.tscn").instantiate()
	return Target.new()
func adopt(target: Node3D) -> void:
	if not target.hit.is_connected(host.on_hit):target.hit.connect(host.on_hit)
	if not is_instance_valid(host.root) or target.get_parent()==host.root:return
	if target.uid.is_empty():target.uid=host.store.next_id()
	if not host.targets.has(target):host.targets.append(target)
func committed(target: Node3D) -> void:
	adopt(target)
	if is_instance_valid(host.root):
		target.reparent(host.root)
		host.dirty=true
		host.save_working()
func before_place() -> void:
	var interface=lib._caller
	var item=interface.contextItem
	if item and str(item.slotData.itemData.file).begins_with("ShootingRange_"):
		if is_instance_valid(host.root) and host.targets.size()>=host.store.LIMIT:
			interface.contextItem=null
			host.notice("Range limit: 40 pieces. Remove one before placing another.")
			return
		host.session.abandon()
		host.game_data.decor=true
func before_save(_shelter: Variant) -> void:
	# Native saves iterate every Furniture body; each assembly has several.
	# Keep its canonical body so a shelter stores exactly one item per piece.
	saved_groups.clear()
	for body in get_tree().get_nodes_in_group("Furniture"):
		if not body.has_meta("range_target"):continue
		var target=body.get_meta("range_target",null)
		if is_instance_valid(target) and body!=target.get_node_or_null("Bounds/Body"):
			body.remove_from_group("Furniture")
			saved_groups.append(body)
func after_save(_shelter: Variant) -> void:
	for body in saved_groups:
		if is_instance_valid(body):body.add_to_group("Furniture")
	saved_groups.clear()
func fill_trader() -> void:
	# Vanilla builds supply from LT_Master; furniture must stay out of loot.
	var trader=lib._caller
	if not registered or not trader.traderData or trader.traderData.name!="Generalist":return
	for kind in Catalog.TYPES:
		var item=load(DIR+kind+"_F.tres")
		if item.generalist and not trader.traderBucket.has(item):trader.traderBucket.append(item)
func before_shot(_spread: float) -> void:
	shot_depth+=1
	Engine.set_meta("RangePlayerShot",true)
func after_shot(_spread: float) -> void:
	shot_depth=maxi(0,shot_depth-1)
	Engine.set_meta("RangePlayerShot",shot_depth>0)
func _unhandled_input(event: InputEvent) -> void:
	if not registered or host.blocked() or host.editor.opened:return
	if event.is_action_pressed("decor") and host.game_data and not host.game_data.shelter:
		host.game_data.decor=not host.game_data.decor
		host.notice("Furniture mode / Tab for catalog" if host.game_data.decor else "Practice mode")
func _exit_tree() -> void:
	if is_instance_valid(lib):
		for id in hooks:lib.unhook(id)
	Engine.remove_meta("RangeShotFilter")
	Engine.remove_meta("RangePlayerShot")
