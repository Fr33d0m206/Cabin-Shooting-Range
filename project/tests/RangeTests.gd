extends SceneTree
const Main=preload("res://mods/ShootingRange/Main.gd")
const Target=preload("res://mods/ShootingRange/Target.gd")
const Catalog=preload("res://mods/ShootingRange/Catalog.gd")
const Placement=preload("res://mods/ShootingRange/Placement.gd")
const Store=preload("res://mods/ShootingRange/LayoutStore.gd")
var failures=0
var checks=0
var world: Node3D
class MapFixture:
	extends Node3D
	var mapName="RangeFixture"
	var mapType="Area"
func _initialize() -> void:run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:failures+=1
	print("CHECK ","PASS " if ok else "FAIL ",message)
func box(point: Vector3, size: Vector3) -> StaticBody3D:
	var body=StaticBody3D.new()
	var shape=BoxShape3D.new()
	shape.size=size
	var collider=CollisionShape3D.new()
	collider.shape=shape
	world.add_child(body)
	body.position=point
	body.add_child(collider)
	return body
func run() -> void:
	world=MapFixture.new()
	world.name="Map"
	root.add_child(world)
	box(Vector3(0,-.5,0),Vector3(200,1,200))
	var placement=Placement.new()
	placement.space=world.get_world_3d().direct_space_state
	await physics_frame
	await physics_frame
	for kind in Catalog.TYPES:
		var target=Target.new()
		target.kind=kind
		target.uid=kind
		world.add_child(target)
		target.position=Vector3(checks*3,0,0)
		await physics_frame
		if kind in ["wall","doorway","window"]:
			check(target.bodies.size()==1,kind+" is modular furniture with no scoring face")
			var middle=target.global_position+Vector3(0,1.4,0)
			var ray=PhysicsRayQueryParameters3D.create(middle+Vector3(0,0,.3),middle-Vector3(0,0,.3))
			check(not placement.space.intersect_ray(ray).is_empty() if kind=="wall" else placement.space.intersect_ray(ray).is_empty(),kind+" wall or cutout collision matches geometry")
			target.queue_free()
			await physics_frame
			continue
		check(target.bodies.size()>=2,kind+" has separate stand and face colliders")
		check(target.paddles.size()==(5 if kind=="rack" else 6 if kind=="tree" else 0 if kind in ["bullseye","silhouette","no_shoot"] else 1),kind+" correct reactive parts")
		var face=target.bodies[1]
		var centre=face.global_position
		if kind in ["bullseye","silhouette","no_shoot"]:
			var ray=PhysicsRayQueryParameters3D.create(centre+Vector3(0,0,2),centre-Vector3(0,0,2))
			check(placement.space.intersect_ray(ray).get("collider")==face,kind+" hit face blocks a native layer-one bullet ray")
			face.register_hit(centre+Vector3(0,0,.01),Vector3.BACK)
		else:
			var position=face.to_global(Vector3(0,0,.007))
			var ray=PhysicsRayQueryParameters3D.create(position+Vector3(0,0,2),position-Vector3(0,0,2))
			check(placement.space.intersect_ray(ray).get("collider")==face,kind+" polygon face blocks bullet ray")
			face.register_hit(position,Vector3.BACK)
		check(target.hits==1 and face.marks.size()==1,kind+" counts actual impacts and retains mark")
		if kind=="torso":
			var notch=face.to_global(Vector3(.16,.25,0))
			var miss=PhysicsRayQueryParameters3D.create(notch+Vector3(0,0,.2),notch-Vector3(0,0,.2))
			check(placement.space.intersect_ray(miss).is_empty(),"torso shoulder cutout has no invisible collision")
		for i in 60:face.register_hit(centre+Vector3(0,0,.01),Vector3.BACK)
		check(face.marks.size()==48,kind+" impact geometry is bounded")
		target.set_editing(true)
		face.register_hit(centre,Vector3.BACK)
		check(target.hits==0,kind+" editor disables scoring and resets reactions")
		target.set_editing(false)
		target.reset()
		check(face.marks.is_empty(),kind+" reset clears marks")
		target.queue_free()
		await physics_frame
	var valid=placement.evaluate(Vector3(0,0,10),"gong",0)
	check(valid.valid and absf(valid.position.y-.01)<.001,"flat supported terrain accepted")
	var wall=box(Vector3(0,1,10),Vector3(1,2,1))
	await physics_frame
	await physics_frame
	check(not placement.evaluate(Vector3(0,0,10),"gong",0).valid,"occupied footprint rejected")
	wall.queue_free()
	await physics_frame
	check(not placement.evaluate(Vector3(101,0,0),"gong",0).valid,"placement distance bound")
	check(not placement.evaluate(Vector3(0,8,0),"gong",0).valid,"unsupported ground rejected")
	var edge=box(Vector3(4,.15,10),Vector3(.5,.3,1))
	await physics_frame
	await physics_frame
	check(not placement.evaluate(Vector3(4,0,10),"rack",0).valid,"uneven multi-foot support rejected")
	edge.queue_free()
	var store=Store.new()
	store.path="user://test-range.cfg"
	var rows=[{"kind":"gong","uid":"one","position":[1.0,.01,3.0],"yaw":.2}]
	check(store.write("Village","working",rows),"atomic layout write")
	check(store.write("Village","working",rows),"atomic replacement of existing layout")
	check(store.read("Village","working")==rows,"layout roundtrip retains transforms and ids")
	check(not store.valid([{"kind":"invalid"}]),"malformed rows rejected")
	var invalid=rows.duplicate(true)
	invalid[0].position[0]=NAN
	check(not store.valid(invalid),"non-finite saved position rejected")
	check(not store.valid(rows+rows),"duplicate ids rejected")
	invalid=rows.duplicate(true)
	invalid[0].yaw=INF
	check(not store.valid(invalid),"non-finite rotation rejected")
	var massive=[]
	for i in 41:
		var row=rows[0].duplicate(true)
		row.uid=str(i)
		massive.append(row)
	check(not store.valid(massive),"layout count bounded")
	store.path="user://missing/subdir/layout.cfg"
	check(not store.write("Village","working",[]),"failed save reported and does not erase in-memory previous layout")
	check(store.read("Village","working")==rows,"failed transaction rolled back")
	# Editor lifecycle uses a native-shaped Core fixture with no global bindings changed.
	var core=Node3D.new()
	core.name="Core"
	world.add_child(core)
	var player=CharacterBody3D.new()
	player.name="Controller"
	core.add_child(player)
	var camera=Camera3D.new()
	core.add_child(camera)
	camera.position=Vector3(0,2,4)
	camera.look_at(Vector3(0,1,0))
	camera.make_current()
	var host=Main.new()
	root.add_child(host)
	host.set_process(false)
	host.active_map=world
	host.map_key="RangeFixture"
	host.root=Node3D.new()
	world.add_child(host.root)
	host.placement.space=placement.space
	await physics_frame
	var bindings=InputMap.action_get_events("ui_accept").size()
	var shortcut=InputEventKey.new()
	shortcut.keycode=KEY_F4
	shortcut.physical_keycode=KEY_F4
	shortcut.pressed=true
	Input.parse_input_event(shortcut)
	await physics_frame
	await process_frame
	check(host.editor.opened and core.process_mode==Node.PROCESS_MODE_DISABLED,"editor leases only native Core")
	check(current_scene==null and not paused,"world remains unpaused during editing")
	var target=host.spawn("gong",Vector3(0,.01,10),0)
	await physics_frame
	await physics_frame
	host.editor.start_drag(target,{"position":target.global_position})
	target.position.x=2
	host.editor.cancel_drag()
	check(absf(target.position.x)<.001,"cancel drag restores original position")
	host.editor.fresh=true
	var fresh=host.spawn("square",Vector3(4,.01,10),0)
	host.editor.start_drag(fresh,{"position":fresh.global_position})
	host.editor.cancel_drag()
	check(host.targets.size()==1,"cancel new placement removes only uncommitted target")
	await physics_frame
	host.editor.start_drag(target,{"position":target.global_position})
	target.global_position=Vector3(3,.01,10)
	host.editor.desired_yaw=.1
	host.editor.drop_result={"valid":true,"position":target.global_position}
	host.editor.commit_drag()
	check(absf(target.position.x-3)<.001 and absf(target.rotation.y-.1)<.001,"valid drag commits transform")
	check(host.undo_stack.size()==1,"drag stores exactly one undo snapshot")
	await host.replace_layout(host.undo_stack.pop_back())
	check(host.targets.size()==1 and absf(host.targets[0].position.x)<.001,"undo restores full previous layout")
	var tab=InputEventKey.new()
	tab.pressed=true
	tab.keycode=KEY_TAB
	host.editor._input(tab)
	check(not host.editor.opened,"native interface shortcut releases editor before handoff")
	host.editor.open()
	host.editor.close()
	check(core.process_mode==Node.PROCESS_MODE_INHERIT and root.get_viewport().get_camera_3d()==camera,"close restores native Core and camera")
	check(InputMap.action_get_events("ui_accept").size()==bindings,"native input bindings untouched")
	shortcut.ctrl_pressed=true
	Input.parse_input_event(shortcut)
	await physics_frame
	check(not host.editor.opened,"modified F4 does not claim another shortcut")
	shortcut.ctrl_pressed=false
	shortcut.echo=true
	Input.parse_input_event(shortcut)
	await physics_frame
	check(not host.editor.opened,"key repeat cannot reopen editor")
	shortcut.echo=false
	paused=true
	Input.parse_input_event(shortcut)
	await process_frame
	await process_frame
	check(not host.editor.opened and host.toast.text.contains("Close menus"),"blocked shortcut gives visible feedback")
	paused=false
	shortcut.keycode=KEY_R
	shortcut.physical_keycode=KEY_R
	shortcut.alt_pressed=true
	Input.parse_input_event(shortcut)
	await physics_frame
	await process_frame
	check(host.editor.opened,"Alt+R remains an alternative shortcut")
	Input.parse_input_event(shortcut)
	await physics_frame
	check(not host.editor.opened and core.process_mode==Node.PROCESS_MODE_INHERIT,"shortcut closes and restores player controls")
	shortcut.pressed=false
	Input.parse_input_event(shortcut)
	host.queue_free()
	world.queue_free()
	await process_frame
	print("RANGE_TESTS_COMPLETE checks=",checks," failures=",failures)
	quit(1 if failures else 0)
