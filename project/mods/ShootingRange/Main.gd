extends Node
const Target=preload("res://mods/ShootingRange/Target.gd")
const Store=preload("res://mods/ShootingRange/LayoutStore.gd")
const Placement=preload("res://mods/ShootingRange/Placement.gd")
const Editor=preload("res://mods/ShootingRange/Editor.gd")
const Catalog=preload("res://mods/ShootingRange/Catalog.gd")
const Session=preload("res://mods/ShootingRange/Session.gd")
const Feedback=preload("res://mods/ShootingRange/ScoreFeedback.gd")
const FurnitureBridge=preload("res://mods/ShootingRange/FurnitureBridge.gd")
var store=Store.new()
var session=Session.new()
var feedback: CanvasLayer
var furniture_bridge: Node
var placement=Placement.new()
var editor: Node
var root: Node3D
var active_map: Node3D
var map_key=""
var game_data: Resource
var targets: Array[Node3D]=[]
var timer=0.0
var loading=false
var generation=0
var dirty=false
var open_requested=false
var toast: Label
var toast_time=0.0
var undo_stack: Array[Array]=[]

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	if ResourceLoader.exists("res://Resources/GameData.tres"):game_data=load("res://Resources/GameData.tres")
	session.store=store
	feedback=Feedback.new()
	feedback.session=session
	add_child(feedback)
	furniture_bridge=FurnitureBridge.new()
	furniture_bridge.host=self
	add_child(furniture_bridge)
	editor=Editor.new()
	editor.host=self
	add_child(editor)
	var layer=CanvasLayer.new()
	layer.layer=99
	add_child(layer)
	toast=Label.new()
	toast.add_theme_font_size_override("font_size",18)
	toast.add_theme_color_override("font_color",Color(.90,.80,.58))
	toast.add_theme_color_override("font_shadow_color",Color.BLACK)
	toast.add_theme_constant_override("shadow_offset_y",2)
	layer.add_child(toast)
	toast.hide()
	print("[ShootingRange] 0.2.4 ready / F4 or Alt+R outdoors / native furniture + arcade scoring")

func blocked() -> bool:
	if get_tree().paused:return true
	var loader=get_node_or_null("/root/Loader")
	if loader and loader.get("masterActive")==false:return true
	if game_data:
		for key in ["freeze","menu","interface","settings","isDead","isTransitioning","isCaching","isTrading","isSleeping","isPlacing"]:
			if game_data.get(key)==true:return true
	return false

func notice(message: String) -> void:
	toast.text=message
	toast.position=Vector2(28,get_viewport().get_visible_rect().size.y-76)
	toast.show()
	toast_time=4.0
	if editor.opened:editor.ui.status.text=message

func _process(delta: float) -> void:
	feedback.set_enabled(not blocked() and not editor.opened and get_node_or_null("/root/Map/Core/Controller")!=null)
	if toast_time>0:
		toast_time-=delta
		if toast_time<=0:toast.hide()
	if is_instance_valid(active_map) and (active_map!=get_node_or_null("/root/Map") or blocked()):
		if editor.opened:editor.close()
	if is_instance_valid(active_map) and active_map==get_node_or_null("/root/Map"):return
	if active_map!=null or root!=null:detach()
	timer-=delta
	if timer>0 or blocked():return
	timer=.5
	var map=get_node_or_null("/root/Map") as Node3D
	var player=get_node_or_null("/root/Map/Core/Controller") as CharacterBody3D
	if not map or not player:return
	if str(map.get("mapType"))=="Shelter":return
	active_map=map
	map_key=str(map.get("mapName"))
	root=Node3D.new()
	root.name="CabinShootingRange"
	map.add_child(root)
	placement.space=root.get_world_3d().direct_space_state
	placement.max_distance=10000
	var cabin=map.get_node_or_null("Content/Prefabs/Cabin_Area") as Node3D
	placement.anchor=cabin.global_position if cabin else player.global_position
	generation+=1
	initialize_range.call_deferred(generation,cabin!=null)

func initialize_range(token: int, has_cabin: bool) -> void:
	loading=true
	if store.has_layout(map_key):
		await restore(store.read(map_key,"working"),token)
	elif has_cabin:
		# Probe the actual terrain around the cabin; never use a hard-coded floor.
		var kinds=["bullseye","silhouette","torso","gong","rack","tree"]
		for kind in kinds:
			if token!=generation or not is_instance_valid(root):return
			for attempt in 48:
				var angle=TAU*attempt/24.0
				var distance=12.0+floorf(attempt/24.0)*6.0
				var point=placement.anchor+Vector3(sin(angle),0,cos(angle))*distance
				var result=placement.evaluate(point,kind,angle+PI)
				if result.valid:
					spawn(kind,result.position,angle+PI)
					await get_tree().physics_frame
					break
		if token==generation:
			dirty=true
			save_working()
	if token==generation:
		loading=false
		save_working()
		if targets.size()>0:notice("CABIN RANGE  /  "+str(targets.size())+" targets ready  /  F4 to arrange")

func spawn(kind: String, point: Vector3, yaw: float, uid="") -> Node3D:
	var target=furniture_bridge.create(kind)
	target.kind=kind
	target.uid=store.next_id() if uid.is_empty() else uid
	root.add_child(target)
	target.global_position=point
	target.rotation.y=yaw
	target.set_editing(editor.opened)
	target.hit.connect(on_hit)
	targets.append(target)
	return target

func on_hit(_target: Node3D, event: Dictionary) -> void:
	if not blocked() and not editor.opened:session.register(event)

func rows() -> Array:
	var result=[]
	for target in targets:
		if is_instance_valid(target):result.append(target.record())
	return result

func checkpoint() -> void:
	session.abandon()
	undo_stack.append(rows())
	if undo_stack.size()>20:undo_stack.pop_front()
	dirty=true

func save_working() -> bool:
	if loading or not dirty:return true
	if store.write(map_key,"working",rows()):
		dirty=false
		return true
	notice("Layout could not save. Targets are still available this session.")
	return false

func restore(records: Array, token: int) -> void:
	var rejected=0
	for row in records:
		await get_tree().physics_frame
		if token!=generation or not is_instance_valid(root):return
		var p=row.position
		var point=Vector3(p[0],p[1],p[2])
		# Saved placements can be anywhere on this map, within bounded coordinates.
		var old_anchor=placement.anchor
		placement.anchor=point
		var result=placement.evaluate(point,row.kind,row.yaw)
		placement.anchor=old_anchor
		if result.valid:spawn(row.kind,result.position,row.yaw,row.uid)
		else:rejected+=1
	if rejected>0:notice(str(rejected)+" saved targets blocked by this map; saved file retained.")

func replace_layout(records: Array) -> void:
	if loading or not store.valid(records):return
	editor.cancel_drag()
	editor.select(null)
	loading=true
	for target in targets:target.queue_free()
	targets.clear()
	var token=generation
	await restore(records,token)
	if token!=generation:return
	loading=false
	dirty=true
	save_working()

func reset_hits() -> void:
	for target in targets:target.reset()
	session.free_practice()
	notice("Targets reset / fresh faces and upright paddles")

func start_round(seconds: int) -> void:
	if loading or not targets.any(func(t):return t.kind not in ["wall","doorway","window"]):
		notice("Place at least one scoring target first.")
		return
	editor.close()
	for target in targets:target.reset()
	feedback.set_enabled(true)
	session.start(seconds,map_key,rows())

func detach() -> void:
	session.abandon()
	editor.close()
	generation+=1
	if is_instance_valid(root):root.queue_free()
	root=null
	active_map=null
	targets.clear()
	undo_stack.clear()
	loading=false
	dirty=false

func _physics_process(_delta: float) -> void:
	session.tick(_delta,blocked() or editor.opened or get_node_or_null("/root/Map/Core/Controller")==null)
	if open_requested:
		open_requested=false
		editor.open()

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:return
	var key=event.physical_keycode if event.physical_keycode else event.keycode
	if event.ctrl_pressed or event.shift_pressed or event.meta_pressed:return
	if not (key==KEY_F4 and not event.alt_pressed) and not (key==KEY_R and event.alt_pressed):return
	get_viewport().set_input_as_handled()
	print("[ShootingRange] editor shortcut: ",event.as_text())
	if editor.opened:editor.close()
	else:open_requested=true

func _exit_tree() -> void:
	if is_instance_valid(editor):editor.close()
