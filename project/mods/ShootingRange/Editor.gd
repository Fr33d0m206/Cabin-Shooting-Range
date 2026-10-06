extends Node
const UI=preload("res://mods/ShootingRange/RangeUI.gd")
const Catalog=preload("res://mods/ShootingRange/Catalog.gd")
var host: Node
var ui: CanvasLayer
var opened=false
var camera: Camera3D
var original_camera: Camera3D
var core: Node
var core_mode=Node.PROCESS_MODE_INHERIT
var mouse_mode=Input.MOUSE_MODE_CAPTURED
var selected: Node3D
var dragged=false
var fresh=false
var before=Transform3D.IDENTITY
var drag_offset=Vector3.ZERO
var drop_result: Dictionary={}
var desired_yaw=0.0
var focus=Vector3.ZERO
var yaw=0.0
var distance=13.0
var pitch=.73
var pending_kind=""
var finish_drag=false

func _ready() -> void:
	ui=UI.new()
	ui.editor=self
	add_child(ui)

func open() -> void:
	if opened:return
	if host.blocked():
		host.notice("Close menus or finish your current action before opening the range editor.")
		return
	if host.loading:
		host.notice("Range is loading. Try again in a moment.")
		return
	if not is_instance_valid(host.root):
		host.notice("The range editor works outdoors. Exit the shelter and let the area load.")
		return
	original_camera=get_viewport().get_camera_3d()
	core=host.active_map.get_node_or_null("Core")
	if not original_camera or not core:
		host.notice("Range controls are not ready. Wait for the area to finish loading.")
		return
	focus=original_camera.global_position-original_camera.global_basis.z*6
	focus.y=original_camera.global_position.y-.9
	yaw=original_camera.global_rotation.y
	distance=13
	core_mode=core.process_mode
	core.process_mode=Node.PROCESS_MODE_DISABLED
	mouse_mode=Input.mouse_mode
	camera=Camera3D.new()
	host.root.add_child(camera)
	camera.fov=55
	camera.far=300
	camera.cull_mask=original_camera.cull_mask
	opened=true
	host.session.abandon()
	update_camera()
	camera.make_current()
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	for target in host.targets:target.set_editing(true)
	ui.show_editor()

func close() -> void:
	if not opened:return
	cancel_drag()
	select(null)
	opened=false
	pending_kind=""
	host.save_working()
	for target in host.targets:
		if is_instance_valid(target):target.set_editing(false)
	if is_instance_valid(core) and core.process_mode==Node.PROCESS_MODE_DISABLED:core.process_mode=core_mode
	if is_instance_valid(original_camera):original_camera.make_current()
	if is_instance_valid(camera):camera.queue_free()
	camera=null
	if Input.mouse_mode==Input.MOUSE_MODE_VISIBLE and not host.blocked():Input.mouse_mode=mouse_mode
	ui.hide()

func update_camera() -> void:
	camera.global_position=focus+Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*distance
	camera.look_at(focus)

func select(target: Node3D) -> void:
	if is_instance_valid(selected):selected.highlight(false)
	selected=target
	if is_instance_valid(selected):selected.highlight(true)
	ui.selection_changed(selected)

func begin_new(kind: String) -> void:
	if host.loading:return
	cancel_drag()
	if host.targets.size()>=host.store.LIMIT:
		host.notice("Range limit: 40 targets. Remove one before adding another.")
		return
	pending_kind=kind
	ui.status.text="Click clear ground to place "+Catalog.TYPES[kind].name+" / right-click cancels"

func cancel_drag() -> void:
	pending_kind=""
	if not dragged:return
	if is_instance_valid(selected):
		if fresh:
			host.targets.erase(selected)
			selected.queue_free()
			select(null)
		else:selected.global_transform=before
	dragged=false
	fresh=false
	drop_result={}
	finish_drag=false

func start_drag(target: Node3D, ground: Dictionary) -> void:
	select(target)
	dragged=true
	before=target.global_transform
	desired_yaw=target.rotation.y
	drag_offset=target.global_position-ground.position if not ground.is_empty() else Vector3.ZERO
	drag_offset.y=0

func ground_cursor() -> Dictionary:
	var ignore: Array[RID]=[]
	for target in host.targets:ignore.append_array(target.rids())
	return host.placement.cursor(camera,get_viewport().get_mouse_position(),ignore)

func _physics_process(delta: float) -> void:
	if not opened:return
	if host.blocked() or not is_instance_valid(host.active_map) or get_viewport().get_camera_3d()!=camera or Input.mouse_mode!=Input.MOUSE_MODE_VISIBLE:
		close()
		return
	if not dragged:
		var motion=Vector3(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),0,float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
		if Input.is_physical_key_pressed(KEY_CTRL) or Input.is_physical_key_pressed(KEY_ALT):motion=Vector3.ZERO
		focus+=Basis(Vector3.UP,yaw)*motion*delta*distance*.5
		update_camera()
		return
	var floor=ground_cursor()
	if floor.is_empty():
		drop_result={"valid":false,"reason":"Aim at clear ground"}
	else:
		var point=floor.position+drag_offset
		if ui.snap.button_pressed:
			point.x=snappedf(point.x,.25)
			point.z=snappedf(point.z,.25)
		drop_result=host.placement.evaluate(point,selected.kind,desired_yaw,selected.rids())
		selected.global_position=drop_result.get("position",point)
		selected.rotation.y=desired_yaw
	selected.highlight(true,drop_result.valid)
	ui.status.text=drop_result.reason+" / Q E rotate / release to set / Esc cancels"
	if finish_drag:
		finish_drag=false
		commit_drag()

func commit_drag() -> void:
	if not dragged:return
	if not drop_result.get("valid",false):
		host.notice(drop_result.get("reason","Placement cancelled"))
		cancel_drag()
		return
	# Revalidate the final position against the live physics world.
	var result=host.placement.evaluate(selected.global_position,selected.kind,selected.rotation.y,selected.rids())
	if not result.valid:
		host.notice(result.reason)
		cancel_drag()
		return
	selected.global_transform=before
	if fresh:
		host.targets.erase(selected)
		host.checkpoint()
		host.targets.append(selected)
	else:host.checkpoint()
	selected.global_position=result.position
	selected.rotation.y=desired_yaw
	dragged=false
	fresh=false
	selected.highlight(true)
	host.save_working()
	ui.selection_changed(selected)
	ui.status.text="Placed / drag to move / Ctrl+D duplicate / Delete remove"

func rotate_selected(amount: float) -> void:
	if not is_instance_valid(selected):return
	if dragged:
		desired_yaw+=amount
		return
	var result=host.placement.evaluate(selected.global_position,selected.kind,selected.rotation.y+amount,selected.rids())
	if not result.valid:host.notice(result.reason);return
	host.checkpoint()
	selected.rotation.y+=amount
	host.save_working()

func remove_selected() -> void:
	if host.loading or not is_instance_valid(selected):return
	cancel_drag()
	if not is_instance_valid(selected):return
	host.checkpoint()
	host.targets.erase(selected)
	selected.queue_free()
	select(null)
	host.save_working()

func duplicate_selected() -> void:
	if is_instance_valid(selected):begin_new(selected.kind)

func _input(event: InputEvent) -> void:
	if not opened:return
	# Return controls before another mod handles its own menu/tablet shortcut.
	if event is InputEventKey and event.pressed and not event.echo:
		var key=event.physical_keycode if event.physical_keycode else event.keycode
		if key in [KEY_F5,KEY_F6,KEY_F7,KEY_F8,KEY_F9,KEY_F10,KEY_F11,KEY_TAB]:close()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed and dragged:
		if ui.panel.get_global_rect().has_point(event.position):cancel_drag()
		else:finish_drag=true

func _unhandled_input(event: InputEvent) -> void:
	if not opened:return
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and not dragged:
		yaw-=event.relative.x*.006
		pitch=clampf(pitch+event.relative.y*.004,.25,1.35)
	elif event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_LEFT:
			if not event.pressed:finish_drag=dragged
			elif host.loading:return
			elif not pending_kind.is_empty():
				var floor=ground_cursor()
				if floor.is_empty():return
				var kind=pending_kind
				var result=host.placement.evaluate(floor.position,kind,yaw)
				if not result.valid:host.notice(result.reason);return
				var target=host.spawn(kind,result.position,yaw)
				pending_kind=""
				fresh=true
				start_drag(target,floor)
				drop_result=result
			else:
				var found=host.placement.cursor(camera,event.position,[])
				if not found.is_empty() and found.collider.has_meta("range_target"):
					start_drag(found.collider.get_meta("range_target"),ground_cursor())
				else:select(null)
		elif event.button_index==MOUSE_BUTTON_RIGHT and event.pressed and (dragged or not pending_kind.is_empty()):cancel_drag()
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			distance=clampf(distance*(.9 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1.1),4,48)
	elif event is InputEventKey and event.pressed and not event.echo:
		var key=event.physical_keycode if event.physical_keycode else event.keycode
		if key==KEY_ESCAPE:
			if dragged or not pending_kind.is_empty():cancel_drag()
			else:close()
		elif key in [KEY_F5,KEY_F6,KEY_F7,KEY_F8,KEY_F9,KEY_F10,KEY_F11]:close()
		elif key==KEY_Q:rotate_selected(deg_to_rad(-15 if event.shift_pressed else -5))
		elif key==KEY_E:rotate_selected(deg_to_rad(15 if event.shift_pressed else 5))
		elif key==KEY_DELETE:remove_selected()
		elif key==KEY_D and event.ctrl_pressed:duplicate_selected()
		elif key==KEY_Z and event.ctrl_pressed and not host.loading:
			cancel_drag()
			if not host.undo_stack.is_empty():host.replace_layout(host.undo_stack.pop_back())
	get_viewport().set_input_as_handled()
