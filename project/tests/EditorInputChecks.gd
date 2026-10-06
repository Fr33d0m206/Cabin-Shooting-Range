extends RefCounted
var host: Node
var verify: Callable
func frames(count=3) -> void:
	for i in count:await host.get_tree().process_frame
func button(text: String) -> Button:
	for node in host.editor.ui.panel.find_children("*","Button",true,false):
		if node.text==text:return node
	return null
func mouse(point: Vector2, pressed: bool) -> void:
	var event=InputEventMouseButton.new()
	event.position=host.get_viewport().get_final_transform()*point
	event.global_position=event.position
	event.button_index=MOUSE_BUTTON_LEFT
	event.pressed=pressed
	event.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0
	Input.parse_input_event(event)
func move_to(point: Vector2, held=false) -> void:
	var move=InputEventMouseMotion.new()
	move.position=host.get_viewport().get_final_transform()*point
	move.global_position=move.position
	move.button_mask=MOUSE_BUTTON_MASK_LEFT if held else 0
	Input.parse_input_event(move)
func click(control: Control) -> void:
	var point=control.get_global_rect().get_center()
	await click_at(point)
func click_at(point: Vector2) -> void:
	move_to(point)
	await frames()
	mouse(point,true)
	await frames(1)
	mouse(point,false)
	await frames()
func choose_slot(index: int) -> bool:
	await click(host.editor.ui.scenario_buttons[index])
	return verify.call(host.editor.ui.slot_index==index and host.editor.ui.scenario_buttons[index].button_pressed,"mouse click selects scenario slot "+str(index+1))
func run(range_host: Node, checker: Callable) -> bool:
	host=range_host
	verify=checker
	await frames(8)
	print("NATIVE_RANGE_EDITOR_VIEWPORT ",host.get_viewport().get_visible_rect()," transform=",host.get_viewport().get_final_transform())
	var library=button("Round gong")
	if not verify.call(library!=null,"editor target library button exists"):return false
	await click(library)
	if not verify.call(host.editor.pending_kind=="gong","mouse click on library arms gong placement"):return false
	if not verify.call(not host.editor.native_ui.visible,"native HUD is hidden while editor owns mouse input"):return false
	await click(button("Save"))
	if not verify.call(host.store.config.has_section_key(host.map_key,"scenario1"),"mouse click saves the first scenario"):return false
	var point=Vector3.ZERO
	var found=false
	var ignore: Array[RID]=[]
	for existing in host.targets:ignore.append_array(existing.rids())
	for i in 48:
		var angle=TAU*i/24.0
		var result=host.placement.evaluate(host.placement.anchor+Vector3(sin(angle),0,cos(angle))*(16+floorf(i/24.0)*5),"gong",0)
		if result.valid:
			host.editor.focus=result.position+Vector3.UP*.4
			host.editor.yaw=0
			host.editor.pitch=1.25
			host.editor.distance=4
			host.editor.update_camera()
			var screen=host.editor.camera.unproject_position(result.position)
			var ray=host.placement.cursor(host.editor.camera,screen,ignore)
			if not ray.is_empty() and ray.position.distance_to(result.position)<.05:
				point=result.position
				found=true
				break
	if not verify.call(found,"clear native ground is available for editor placement"):return false
	host.editor.focus=point+Vector3.UP*.4
	host.editor.yaw=0
	host.editor.distance=4
	host.editor.update_camera()
	await frames(8)
	var screen=host.editor.camera.unproject_position(point)
	var previous=host.targets.size()
	await click_at(screen)
	print("NATIVE_RANGE_EDITOR_STATE screen=",screen," cursor=",host.editor.cursor_position," pending=",host.editor.pending_kind," queue=",host.editor.pointer_events.size()," drag=",host.editor.dragged," result=",host.editor.drop_result," status=",host.editor.ui.status.text," hovered=",host.get_viewport().gui_get_hovered_control())
	if not verify.call(host.targets.size()==previous+1,"clicking native ground commits the selected target"):return false
	if not verify.call(not host.editor.dragged and host.store.read(host.map_key,"working").size()==previous+1,"mouse release commits and persists the new placement"):return false
	var target=host.editor.selected
	var from=target.global_position
	var moved={"valid":false}
	for i in 8:
		var angle=TAU*i/8.0
		moved=host.placement.evaluate(from+Vector3(sin(angle),0,cos(angle))*2,"gong",target.rotation.y,target.rids())
		if moved.valid:break
	if not verify.call(moved.valid,"editor drag destination has supported native ground"):return false
	host.editor.focus=(from+moved.position)*.5+Vector3.UP*.4
	host.editor.distance=6
	host.editor.update_camera()
	await frames(4)
	var face=host.editor.camera.unproject_position(target.bodies[1].global_position)
	move_to(face)
	mouse(face,true)
	await frames(5)
	if not verify.call(host.editor.dragged,"mouse press selects the existing plate for dragging"):return false
	var destination=host.editor.camera.unproject_position(moved.position-host.editor.drag_offset)
	move_to(destination,true)
	await frames(5)
	mouse(destination,false)
	await frames(5)
	if not verify.call(not host.editor.dragged and target.global_position.distance_to(from)>1,"mouse drag and release move the existing target"):return false
	if not await choose_slot(1):return false
	await click(button("Save"))
	if not verify.call(host.store.read(host.map_key,"scenario2").size()==previous+1,"mouse click saves a different second scenario"):return false
	if not await choose_slot(0):return false
	await click(button("Load"))
	while host.loading:await frames(1)
	print("NATIVE_RANGE_SCENARIO_STATE count=",host.targets.size()," expected=",previous," status=",host.editor.ui.status.text," records=",host.store.read(host.map_key,"scenario1"))
	if not verify.call(host.targets.size()==previous,"mouse click loads the first scenario and replaces placed pieces"):return false
	if not await choose_slot(1):return false
	await click(button("Load"))
	while host.loading:await frames(1)
	if not verify.call(host.targets.size()==previous+1,"mouse click loads the second scenario with its additional target"):return false
	if not await choose_slot(2):return false
	await click(button("Load"))
	if not verify.call(host.targets.size()==previous+1 and host.toast.text.contains("empty"),"empty scenario gives feedback and preserves the current layout"):return false
	if not await choose_slot(0):return false
	await click(button("Load"))
	while host.loading:await frames(1)
	if not verify.call(host.targets.size()==previous,"editor scenario test restores the initial course"):return false
	host.editor.cancel_drag()
	return true
