extends Node
var count=0
func check(ok: bool, message: String) -> bool:
	count+=1
	print("NATIVE_RANGE_", "PASS " if ok else "FAIL ",message)
	if not ok:get_tree().quit(1)
	return ok
func _ready() -> void:run.call_deferred()
func wait_frames(frames: int) -> void:
	for i in frames:await get_tree().process_frame
func run() -> void:
	await wait_frames(15)
	var host=get_node_or_null("/root/ShootingRangeMain")
	if not check(host!=null,"packaged mod autoload loaded through real Metro"):return
	var loader=get_node("/root/Loader")
	loader.NewGame(1,1)
	loader.LoadScene("Cabin")
	var data=load("res://Resources/GameData.tres")
	for i in 2400:
		await wait_frames(1)
		if get_tree().current_scene and get_tree().current_scene.get("mapName")=="Cabin" and not data.freeze and not data.isCaching:break
	await get_tree().create_timer(2.0).timeout
	if not check(get_tree().current_scene.get("mapName")=="Cabin","native cabin initialized with isolated saves"):return
	await tap_shortcut(KEY_F4)
	if not check(not host.editor.opened,"interior cabin refuses outdoor editor"):return
	var reactive_only=OS.get_cmdline_user_args().has("--range-reactive-only")
	if not reactive_only and not await furniture_checks(host,loader):return
	if OS.get_cmdline_user_args().has("--range-furniture-only"):
		print("NATIVE_RANGE_COMPLETE furniture_checks=",count)
		get_tree().quit()
		return
	loader.LoadScene("Village")
	for i in 3600:
		await wait_frames(1)
		if get_tree().current_scene and get_tree().current_scene.get("mapName")=="Village" and not data.freeze and not data.isCaching:break
	await get_tree().create_timer(2.0).timeout
	if not check(get_tree().current_scene.get("mapName")=="Village" and not data.freeze,"native village initialized"):return
	for i in 1200:
		await wait_frames(1)
		if is_instance_valid(host.root) and not host.loading and host.targets.size()>0:break
	print("NATIVE_RANGE_TARGETS ",host.rows())
	if not check(host.targets.size()==6,"six starter targets placed on actual cabin terrain"):return
	if not check(host.store.has_layout("Village"),"starter layout persisted outside native saves"):return
	if not check(not loader.screen.visible,"native loading overlay fully dismissed before editing"):return
	var cabin=get_node("/root/Map/Content/Prefabs/Cabin_Area")
	for target in host.targets:
		if not check(target.global_position.distance_to(cabin.global_position)>8 and target.global_position.distance_to(cabin.global_position)<23,"target outside cabin / "+target.kind):return
	if reactive_only:
		if not await recovery_checks(host):return
		print("NATIVE_RANGE_COMPLETE reactive_checks=",count)
		get_tree().quit()
		return
	var player=get_node("/root/Map/Core/Controller")
	var first=host.targets[0]
	player.global_position=first.global_position+first.global_basis.z*4+Vector3.UP*.1
	await wait_frames(5)
	if not await shortcut_checks(host):return
	if OS.get_cmdline_user_args().has("--range-hotkey-only"):
		print("NATIVE_RANGE_COMPLETE hotkey_checks=",count)
		get_tree().quit()
		return
	await tap_shortcut(KEY_F4)
	if not check(host.editor.opened,"F4 opens editor against native player Core"):return
	await wait_frames(5)
	host.editor.focus=cabin.global_position+Vector3(8,1,8)
	host.editor.distance=25
	host.editor.yaw=.4
	host.editor.update_camera()
	await capture("native-editor")
	await tap_shortcut(KEY_F4)
	if not check(get_node("/root/Map/Core").process_mode!=Node.PROCESS_MODE_DISABLED,"closing restores native gameplay"):return
	# Invoke the actual current-pack WeaponRig.Raycast on a guaranteed hit.
	var target=host.targets.filter(func(t):return t.kind=="gong")[0]
	var face=target.bodies[1]
	var ray=RayCast3D.new()
	get_node("/root/Map").add_child(ray)
	ray.global_position=face.global_position+target.global_basis.z*.8
	ray.target_position=ray.to_local(face.global_position-target.global_basis.z*.1)
	ray.collision_mask=1
	ray.enabled=true
	ray.force_raycast_update()
	if not check(ray.get_collider()==face,"actual native terrain scene ray hits gong face"):return
	var rig=load("res://Scripts/WeaponRig.gd").new()
	rig.raycast=ray
	rig.rigManager=get_node("/root/Map/Core/Camera/Manager")
	rig.Raycast(0.0)
	await wait_frames(3)
	if not check(target.hits==1,"real WeaponRig impact counted once"):return
	if not check(host.session.total==100 and host.session.hits==1,"native player impact earns 100 centre points"):return
	if not check(host.session.headshots==0 and host.feedback.title.text!="HEADSHOT","native circular gong never grants a headshot bonus or popup"):return
	if not check(face.marks.size()==1,"real WeaponRig impact retained on gong"):return
	if not check(absf(target.paddles[0].pivot.rotation.x)>.001,"real shot starts steel reaction"):return
	var npc_effect=load("res://Effects/Hit_Default.tscn").instantiate()
	face.add_child(npc_effect)
	await wait_frames(3)
	if not check(target.hits==1,"NPC or unrelated native effects cannot inflate player score"):return
	npc_effect.queue_free()
	var paper=host.targets.filter(func(t):return t.kind=="silhouette")[0]
	var paper_face=paper.bodies[1]
	var head=paper_face.to_global(Vector3(0,.24,0))
	ray.global_position=head+paper.global_basis.z*.6
	ray.target_position=ray.to_local(head-paper.global_basis.z*.1)
	ray.force_raycast_update()
	host.session.cooldown=0
	rig.Raycast(0.0)
	await wait_frames(3)
	if not check(host.session.total==200 and host.session.headshots==1,"native silhouette shot detects head and awards 100 points"):return
	if not check(host.feedback.title.text=="HEADSHOT" and host.feedback.popup.visible,"native headshot uses occasional arcade popup"):return
	rig.free()
	ray.queue_free()
	# Beauty view in the actual Village, with native lighting and textures.
	var camera=Camera3D.new()
	get_node("/root/Map").add_child(camera)
	camera.global_position=paper.global_position+paper.global_basis.z*2.5+Vector3.UP*1.6
	camera.look_at(paper.global_position+Vector3.UP*1.2)
	camera.make_current()
	await capture("native-target-headshot")
	host.session.start(30,"Village",host.rows())
	host.session.total=host.session.best+250
	host.session.hits=3
	host.session.tick(30,false)
	if not check(host.session.mode=="complete" and host.feedback.title.text=="NEW HIGH SCORE!","completed round persists and announces an actual new record"):return
	await capture("native-high-score")
	camera.queue_free()
	host.reset_hits()
	if not check(target.hits==0 and face.marks.is_empty(),"native reset restores fresh target"):return
	var records=host.rows()
	host.dirty=true
	host.save_working()
	loader.LoadScene("Cabin")
	for i in 2400:
		await wait_frames(1)
		if get_tree().current_scene and get_tree().current_scene.get("mapName")=="Cabin" and not data.freeze and not data.isCaching:break
	await wait_frames(40)
	if not check(not is_instance_valid(host.root),"map exit cleans up all target nodes and editor"):return
	loader.LoadScene("Village")
	for i in 3600:
		await wait_frames(1)
		if is_instance_valid(host.root) and host.map_key=="Village" and not host.loading and host.targets.size()==6 and not data.freeze:break
	if not check(host.targets.size()==6,"saved range restored after Cabin to Village travel"):return
	if not check(host.rows().map(func(r):return r.uid)==records.map(func(r):return r.uid),"target ids and layout survive native map travel"):return
	for i in 2400:
		await wait_frames(1)
		if not data.freeze and not data.isCaching and not loader.screen.visible:break
	await wait_frames(3)
	if not await native_placement(host):return
	print("NATIVE_RANGE_COMPLETE checks=",count)
	get_tree().quit()
func key_event(key: int, pressed: bool, alt=false, echo=false, ctrl=false) -> InputEventKey:
	var event=InputEventKey.new()
	event.keycode=key
	event.physical_keycode=key
	event.pressed=pressed
	event.alt_pressed=alt
	event.echo=echo
	event.ctrl_pressed=ctrl
	return event
func tap_shortcut(key: int, alt=false) -> void:
	Input.parse_input_event(key_event(key,true,alt))
	await wait_frames(4)
	Input.parse_input_event(key_event(key,false,alt))
	await wait_frames(2)
func shortcut_checks(host: Node) -> bool:
	var conflicts=[]
	for action in InputMap.get_actions():
		for event in InputMap.action_get_events(action):
			if event is InputEventKey and (event.keycode==KEY_F4 or event.physical_keycode==KEY_F4):conflicts.append(action)
	if not check(conflicts.is_empty(),"F4 has no native InputMap conflicts: "+str(conflicts)):return false
	var core=get_node("/root/Map/Core")
	var prior_mode=core.process_mode
	var prior_camera=get_viewport().get_camera_3d()
	var prior_mouse=Input.mouse_mode
	for combo in [{"key":KEY_F4,"alt":false,"name":"F4"},{"key":KEY_R,"alt":true,"name":"Alt+R"}]:
		Input.parse_input_event(key_event(combo.key,true,combo.alt))
		await wait_frames(4)
		if not check(host.editor.opened,combo.name+" native input dispatch opens range editor"):return false
		if not check(host.editor.ui.visible and core.process_mode==Node.PROCESS_MODE_DISABLED and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,combo.name+" opens visible controls and releases mouse"):return false
		Input.parse_input_event(key_event(combo.key,true,combo.alt,true))
		await wait_frames(2)
		if not check(host.editor.opened,combo.name+" key repeat does not immediately close editor"):return false
		Input.parse_input_event(key_event(combo.key,false,combo.alt))
		await wait_frames(2)
		if not check(host.editor.opened,combo.name+" release does not toggle editor"):return false
		await tap_shortcut(combo.key,combo.alt)
		if not check(not host.editor.opened and core.process_mode==prior_mode and get_viewport().get_camera_3d()==prior_camera and Input.mouse_mode==prior_mouse,combo.name+" closes and restores native controls camera and mouse"):return false
	Input.parse_input_event(key_event(KEY_F4,true,false,false,true))
	await wait_frames(2)
	if not check(not host.editor.opened,"modified F4 leaves other shortcuts alone"):return false
	Input.parse_input_event(key_event(KEY_F4,false,false,false,true))
	return true
func recovery_checks(host: Node) -> bool:
	host.reset_hits()
	var ray=RayCast3D.new()
	get_node("/root/Map").add_child(ray)
	ray.collision_mask=1
	ray.enabled=true
	var rig=load("res://Scripts/WeaponRig.gd").new()
	rig.raycast=ray
	rig.rigManager=get_node("/root/Map/Core/Camera/Manager")
	for kind in ["rack","tree"]:
		var target=host.targets.filter(func(t):return t.kind==kind)[0]
		var item=target.paddles[0]
		var face=item.body
		ray.global_position=face.global_position+target.global_basis.z*.8
		ray.target_position=ray.to_local(face.global_position-target.global_basis.z*.1)
		ray.force_raycast_update()
		if not check(ray.get_collider()==face,"native shot ray hits reactive paddle / "+kind):return false
		rig.Raycast(0.0)
		await get_tree().create_timer(.4).timeout
		if not check(target.hits==1 and item.pivot.rotation.length()>1.2,"native impact knocks paddle out of ready position / "+kind):return false
		while item.tween.is_valid() and item.tween.get_total_elapsed_time()<2.8:await wait_frames(1)
		if not check(item.pivot.rotation.length()>1.2,"native paddle holds until its three-second return / "+kind):return false
		while item.tween.is_valid():await wait_frames(1)
		if not check(item.pivot.rotation.is_equal_approx(item.rest) and not item.side,"native paddle automatically returns ready after three seconds / "+kind):return false
		if not check(target.hits==1 and target.points==100 and face.marks.size()==1,"native recovery preserves earned points and bullet mark / "+kind):return false
		if not check(target.paddles[1].pivot.rotation.is_equal_approx(target.paddles[1].rest),"native unhit paddle is untouched / "+kind):return false
	rig.free()
	ray.queue_free()
	return true
func furniture_checks(host: Node, loader: Node) -> bool:
	if not check(host.furniture_bridge.registered and not host.furniture_bridge.hooks.has(-1),"twelve furniture bundles and all native hooks registered"):return false
	for name in ["MCM","CheatMenuMain","ChickenCompanionMain","InventoryCompatibilityGlowMain","RTVQualityMap","ScavengedDroneMain","StockpileContainerMain"]:
		if not check(get_node_or_null("/root/"+name)!=null,"existing mod stack autoload / "+name):return false
	var cheat=get_node("/root/CheatMenuMain")
	if not check(cheat.catalog_ready,"Furniture Spawner catalog is ready through normal startup"):return false
	var entries=cheat.items_by_category.get("Furniture",[]).filter(func(e):return str(e.get("scene_path","")).begins_with("res://Assets/ShootingRange/"))
	if not check(entries.size()==12,"real Furniture Spawner discovers all twelve range pieces"):return false
	var interface=get_node("/root/Map/Core/UI/Interface")
	var grid=interface.catalogGrid
	var inventory=cheat._ensure_furniture_inventory()
	var before=grid.get_child_count()
	var added=inventory.add_many(entries)
	if not check(added.failed==0 and added.added+added.existing==12,"Spawner adds every design to actual furniture catalog"):return false
	var repeated=inventory.add_many(entries)
	if not check(repeated.existing==12 and repeated.added==0,"repeat spawner action does not duplicate catalog entries"):return false
	for entry in entries:
		var item=load(entry.data_path)
		print("NATIVE_RANGE_ITEM ",item.file," type=",item.type," value=",item.value," icon=",item.icon)
		if not check(item.type=="Furniture" and item.value>0 and item.icon!=null,"priced native item and icon / "+item.file):return false
	# Exercise native Generalist pool generation and an actual barter transaction.
	var trader=load("res://Scripts/Trader.gd").new()
	trader.traderData=load("res://Scripts/TraderData.gd").new()
	trader.traderData.name="Generalist"
	trader.tax=0
	trader.FillTraderBucket()
	if not check(trader.traderBucket.filter(func(i):return i.file.begins_with("ShootingRange_")).size()==12,"real Generalist supply pool contains all range furniture"):trader.free();return false
	var sale=load("res://Scripts/SlotData.gd").new()
	sale.itemData=load("res://Assets/ShootingRange/wall_F.tres")
	sale.condition=100
	trader.supply.append(sale)
	if not check(interface.Create(sale,interface.supplyGrid,false),"priced wall entered native trader supply grid"):trader.free();return false
	var offer=null
	for child in interface.inventoryGrid.get_children():
		if child.Value()>=sale.itemData.value:offer=child;break
	if not check(offer!=null,"isolated new character has real barter goods covering wall price"):trader.free();return false
	var request=interface.supplyGrid.get_child(interface.supplyGrid.get_child_count()-1)
	request.State("Selected")
	offer.State("Selected")
	interface.trader=trader
	interface.CalculateDeal()
	if not check(not interface.acceptButton.disabled,"native deal accepts adequate payment for practice wall"):return false
	var pre_buy=grid.get_child_count()
	interface.CompleteDeal()
	interface.trader=null
	if not check(grid.get_child_count()==pre_buy+1 and trader.supply.is_empty(),"native purchase consumes payment and transfers wall into catalog"):return false
	trader.free()
	await wait_frames(3)
	# Native shelter save must not duplicate an assembly for each hit collider.
	var wall=load("res://Assets/ShootingRange/wall_F.tscn").instantiate()
	get_node("/root/Map").add_child(wall)
	wall.position=Vector3(30,1,30)
	await wait_frames(3)
	loader.SaveShelter("Cabin")
	var saved=ResourceLoader.load("user://Cabin.tres","",ResourceLoader.CACHE_MODE_IGNORE)
	if not check(saved.furnitures.filter(func(f):return f.itemData.file=="ShootingRange_wall").size()==1,"native shelter save contains one record per multi-collider assembly"):return false
	if not check(wall.bodies.all(func(b):return b.is_in_group("Furniture")),"shelter save restores interaction groups"):return false
	wall.queue_free()
	loader.SaveCharacter()
	return true
func native_placement(host: Node) -> bool:
	var interface=get_node("/root/Map/Core/UI/Interface")
	var item=null
	for child in interface.catalogGrid.get_children():
		if child.slotData.itemData.file=="ShootingRange_doorway":item=child;break
	if not check(item!=null,"new furniture item survives real native character save and travel"):return false
	host.game_data.decor=false
	interface.UIManager.ToggleInterface()
	interface.contextItem=item
	interface.contextGrid=interface.catalogGrid
	interface.ContextPlace()
	await wait_frames(3)
	var placer=interface.placer
	var doorway=placer.placable
	if not check(is_instance_valid(doorway) and doorway.kind=="doorway" and placer.furniture.isMoving,"native ContextPlace spawns custom doorway in outdoor Village"):return false
	if not check(host.game_data.decor and doorway.editing and doorway.bodies.all(func(b):return b.collision_layer==0),"native movement disables self collision and scoring"):return false
	# Hold the native Placer still while testing its real floor rays and commit.
	placer.set_physics_process(false)
	var result={}
	for attempt in 100:
		var p=host.placement.anchor+Vector3(sin(attempt*.25),0,cos(attempt*.25))*25
		result=host.placement.evaluate(p,"doorway",0)
		if result.valid:break
	if not check(result.get("valid",false),"modular doorway has a valid native Village footprint"):return false
	doorway.global_position=result.position
	doorway.rotation=Vector3.ZERO
	await wait_frames(12)
	for ray in placer.furniture.rays.get_children():ray.force_raycast_update()
	placer.furniture.CheckOverlap()
	placer.furniture.CheckRays()
	if not check(placer.furniture.CanPlace(),"actual native Furniture.CanPlace validates doorway support"):return false
	placer.furniture.ResetMove()
	var helper=placer.furniture
	placer.placable=null
	placer.furniture=null
	host.game_data.isPlacing=false
	placer.set_physics_process(true)
	if not check(doorway.get_parent()==host.root and host.targets.has(doorway) and doorway.bodies.all(func(b):return b.collision_layer==1),"native commit restores collision and joins persistent range layout"):return false
	if not check(host.store.read("Village","working").size()==7,"native furniture placement saved in map arrangement"):return false
	var count_before=interface.catalogGrid.get_child_count()
	helper.Catalog()
	await wait_frames(3)
	if not check(host.targets.size()==6 and interface.catalogGrid.get_child_count()==count_before+1,"native return to catalog removes world piece and restores catalog item"):return false
	host.game_data.decor=false
	return true
func capture(name: String) -> void:
	await get_tree().create_timer(.3).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://"+name+".png")
