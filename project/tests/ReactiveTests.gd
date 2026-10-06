extends SceneTree
const Target=preload("res://mods/ShootingRange/Target.gd")
const Catalog=preload("res://mods/ShootingRange/Catalog.gd")
var checks=0
var failures=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok:failures+=1
	print("CHECK ","PASS " if ok else "FAIL ",label)
func shoot(item: Dictionary) -> void:
	item.body.register_hit(item.body.global_position,Vector3.BACK)
func at_rest(item: Dictionary) -> bool:
	return item.pivot.rotation.is_equal_approx(item.rest)
func run() -> void:
	for kind in ["gong","torso","square","diamond"]:hanging_checks(kind)
	for kind in ["rack","tree"]:
		var target=Target.new()
		target.kind=kind
		root.add_child(target)
		var first=target.paddles[0]
		var stem=null
		for child in first.body.get_children():
			if child is MeshInstance3D and child.mesh is BoxMesh:stem=child;break
		check(stem!=null and stem.position.z+stem.mesh.size.z*.5<-.003,kind+" attachment front stays behind paddle face")
		shoot(first)
		first.tween.custom_step(.30)
		check(first.pivot.rotation.length()>1.2,kind+" reacts to the impact")
		check(at_rest(target.paddles[1]),kind+" unhit paddles remain still")
		first.tween.custom_step(2.65)
		check(first.pivot.rotation.length()>1.2,kind+" holds until three seconds after impact")
		first.tween.custom_step(.20)
		check(first.pivot.rotation.length()>0 and first.pivot.rotation.length()<(PI if kind=="tree" else PI*.46),kind+" smoothly returns after three seconds")
		first.tween.custom_step(.20)
		check(at_rest(first) and not first.side,kind+" restores the original ready position")
		check(target.hits==1 and target.points==100 and first.body.marks.size()==1,kind+" recovery preserves scores and impact marks")
		# Each paddle recovers independently; hitting another does not reset its peer.
		shoot(first)
		first.tween.custom_step(.30)
		var second=target.paddles[1]
		shoot(second)
		second.tween.custom_step(.30)
		first.tween.custom_step(3.05)
		second.tween.custom_step(2.65)
		check(at_rest(first) and second.pivot.rotation.length()>1.2,kind+" separate paddles have separate recovery clocks")
		var old=second.tween
		shoot(second)
		check(not old.is_valid() and second.tween.is_valid(),kind+" another impact cancels old recovery")
		second.tween.custom_step(3.35)
		check(at_rest(second) and not second.side,kind+" repeated hits still end in a ready state")
		shoot(first)
		var pending=first.tween
		pending.custom_step(.4)
		target.set_editing(true)
		check(not pending.is_valid() and at_rest(first),kind+" editing cancels pending recovery")
		target.set_editing(false)
		shoot(first)
		pending=first.tween
		pending.custom_step(.4)
		target.reset()
		check(not pending.is_valid() and at_rest(first) and target.hits==0,kind+" manual reset safely cancels pending recovery")
		if kind=="rack":
			shoot(first)
			first.tween.custom_step(2.90)
			old=first.tween
			shoot(first)
			first.tween.custom_step(2.95)
			check(not old.is_valid() and first.pivot.rotation.length()>1.2,"rack recovery countdown restarts on its latest hit")
			first.tween.custom_step(.4)
			check(at_rest(first),"rack readies again after the renewed countdown")
		shoot(first)
		pending=first.tween
		target.free()
		await process_frame
		await process_frame
		check(not pending.is_valid(),kind+" removal cancels bound recovery without stale callbacks")
	print("REACTIVE_TESTS_COMPLETE checks=",checks," failures=",failures)
	quit(1 if failures else 0)

func hanging_checks(kind: String) -> void:
	var target=Target.new()
	target.kind=kind
	root.add_child(target)
	target.rotation.y=.47
	var item=target.paddles[0]
	var polygon=Catalog.polygon(kind)
	var anchors=[]
	for side in ["Left","Right"]:
		var chain=item.pivot.get_node("Chain"+side)
		var pin=item.body.get_node("Mount"+side)
		var first=chain.get_child(0)
		var last=chain.get_child(chain.get_child_count()-1)
		anchors.append(first.global_position)
		check(first.global_position.distance_to(target.to_global(Vector3(pin.position.x,1.70,.020)))<.0001,kind+" "+side+" chain meets the beam")
		check(last.global_position.distance_to(pin.global_position)<.015,kind+" "+side+" chain reaches its plate pin")
		var contained=true
		for angle in 24:
			var point=Vector2(pin.position.x,pin.position.y)+Vector2(cos(TAU*angle/24),sin(TAU*angle/24))*.015
			contained=contained and Geometry2D.is_point_in_polygon(point,polygon)
		check(contained,kind+" "+side+" mounting hardware stays inside the plate profile")
		var linked=true
		for i in chain.get_child_count()-1:
			var a=chain.get_child(i)
			var b=chain.get_child(i+1)
			var bounds_a=a.transform*a.mesh.get_aabb()
			var bounds_b=b.transform*b.mesh.get_aabb()
			linked=linked and bounds_a.intersects(bounds_b)
		check(linked,kind+" "+side+" alternating links interlock without gaps")
	shoot(item)
	item.tween.custom_step(.08)
	for i in 2:
		var side="Left" if i==0 else "Right"
		var chain=item.pivot.get_node("Chain"+side)
		var pin=item.body.get_node("Mount"+side)
		check(chain.get_child(0).global_position.distance_to(anchors[i])<.0001,kind+" "+side+" top attachment stays fixed during swing")
		check(chain.get_child(chain.get_child_count()-1).global_position.distance_to(pin.global_position)<.015,kind+" "+side+" lower attachment follows the swinging plate")
	item.tween.custom_step(1.2)
	check(at_rest(item),kind+" complete hanging assembly settles back to rest")
	target.free()
