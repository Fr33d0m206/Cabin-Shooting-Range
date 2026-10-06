extends Node3D
signal hit(target: Node3D, event: Dictionary)
const Catalog=preload("res://mods/ShootingRange/Catalog.gd")
const Geo=preload("res://mods/ShootingRange/Geometry.gd")
const Mat=preload("res://mods/ShootingRange/Materials.gd")
const HitBody=preload("res://mods/ShootingRange/HitBody.gd")
const Rules=preload("res://mods/ShootingRange/ScoreRules.gd")
const Props=preload("res://mods/ShootingRange/PracticeProps.gd")
const AUTO_RESET_SECONDS=3.0
@export var kind="gong"
var uid=""
var bodies: Array[StaticBody3D]=[]
var paddles: Array[Dictionary]=[]
var hits=0
var points=0
var indicator: MeshInstance3D
var tag: Label3D
var editing=false
var support: StaticBody3D

func _ready() -> void:
	name="Range_"+kind+"_"+uid
	support=HitBody.new()
	support.surface="Wood" if kind in ["bullseye","silhouette","no_shoot","wall","doorway","window"] else "Metal"
	support.range_target=self
	support.collision_layer=1
	support.collision_mask=0
	support.set_meta("range_target",self)
	add_child(support)
	bodies.append(support)
	if kind in ["bullseye","silhouette","no_shoot"]:paper()
	elif kind in ["wall","doorway","window"]:Props.build(self,kind)
	elif kind=="rack":rack()
	elif kind=="tree":tree()
	else:hanging()
	tag=Label3D.new()
	tag.text=Catalog.TYPES[kind].name.to_upper()
	tag.font_size=24
	tag.pixel_size=.0008
	tag.modulate=Color(.84,.75,.53)
	tag.outline_size=4
	var tag_height=.87 if kind in ["bullseye","silhouette","no_shoot"] else 2.31 if kind in ["wall","doorway","window"] else 1.74 if kind not in ["rack","tree"] else .38
	Geo.box(self,Vector3(.34,.05,.008),Vector3(0,tag_height,.037),Mat.surface("steel"))
	tag.position=Vector3(0,tag_height,.043)
	add_child(tag)
	indicator=MeshInstance3D.new()
	var ring=TorusMesh.new()
	ring.inner_radius=.54
	ring.outer_radius=.56
	ring.rings=48
	ring.ring_segments=6
	indicator.mesh=ring
	var material=StandardMaterial3D.new()
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color=Color(.83,.69,.36)
	indicator.material_override=material
	indicator.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(indicator)
	indicator.position.y=.025
	indicator.hide()

func beam(size: Vector3, point: Vector3, wood=false) -> void:
	Geo.box(support,size,point,Mat.surface("wood" if wood else "steel"))
	var shape=BoxShape3D.new()
	shape.size=size
	var node=CollisionShape3D.new()
	node.shape=shape
	support.add_child(node)
	node.position=point

func foot(width: float) -> void:
	for x in [-width*.5,width*.5]:
		beam(Vector3(.065,.06,.78),Vector3(x,.04,0))
		beam(Vector3(.085,.018,.1),Vector3(x,.01,-.34))
		beam(Vector3(.085,.018,.1),Vector3(x,.01,.34))

func paddle(point: Vector3, polygon: PackedVector2Array, mode: String, offset=Vector3.ZERO) -> StaticBody3D:
	var pivot=Node3D.new()
	add_child(pivot)
	pivot.position=point
	var body=HitBody.new()
	body.range_target=self
	body.set_meta("range_target",self)
	pivot.add_child(body)
	body.position=offset
	Geo.collider(body,Geo.plate(body,polygon,.012))
	bodies.append(body)
	var item={"pivot":pivot,"body":body,"mode":mode,"side":false,"tween":null,"rest":pivot.rotation}
	paddles.append(item)
	body.struck.connect(on_struck.bind(item))
	return body

func paper() -> void:
	foot(.72)
	for x in [-.29,.29]:
		beam(Vector3(.042,1.78,.042),Vector3(x,.90,-.035),true)
	beam(Vector3(.66,.035,.045),Vector3(0,1.68,-.035),true)
	beam(Vector3(.66,.035,.045),Vector3(0,.87,-.035),true)
	var body=HitBody.new()
	body.surface="Wood"
	body.range_target=self
	body.set_meta("range_target",self)
	add_child(body)
	body.position=Vector3(0,1.29,.012)
	bodies.append(body)
	Geo.box(body,Vector3(.69,.90,.018),Vector3.ZERO,Mat.surface("card"))
	var shape=BoxShape3D.new()
	shape.size=Vector3(.69,.90,.018)
	Geo.collider(body,shape)
	var sheet=MeshInstance3D.new()
	var quad=QuadMesh.new()
	quad.size=Vector2(.62,.62 if kind=="bullseye" else .82)
	sheet.mesh=quad
	sheet.material_override=Mat.print_material(kind)
	body.add_child(sheet)
	sheet.position.z=.010
	body.struck.connect(on_struck.bind({"body":body,"mode":"paper"}))
	for x in [-.28,.28]:
		Geo.box(body,Vector3(.018,.028,.006),Vector3(x,.38,.014),Mat.surface("steel"))

func hanging() -> void:
	foot(1.02)
	for x in [-.5,.5]:
		beam(Vector3(.05,1.73,.05),Vector3(x,.90,0))
		Geo.rod(support,Vector3(x,.12,-.32),Vector3(x,1.15,0),.018,Mat.surface("steel"))
	beam(Vector3(1.16,.065,.055),Vector3(0,1.74,0))
	var center=1.17 if kind!="torso" else 1.10
	# Suspend the whole assembly from the beam, including both chains.
	var body=paddle(Vector3(0,1.70,.020),Catalog.polygon(kind),"swing",Vector3(0,center-1.70,-.020))
	var mount_y={"torso":.36,"gong":.09,"square":.11,"diamond":.105}[kind]
	for x in [-.085,.085]:
		var mount=Vector3(x,mount_y,.020)
		var metal=Mat.surface("steel")
		Geo.rod(body,mount-Vector3(0,0,.008),mount-Vector3(0,0,.004),.014,metal)
		var pin=Geo.rod(body,mount-Vector3(0,0,.013),mount+Vector3(0,0,.010),.006,metal)
		pin.name="MountLeft" if x<0 else "MountRight"
		Geo.rod(body,mount+Vector3(0,0,.006),mount+Vector3(0,0,.012),.009,metal)
		var chain=Geo.chain(body.get_parent(),x,0,body.position.y+mount_y+.010)
		chain.name="ChainLeft" if x<0 else "ChainRight"

func rack() -> void:
	foot(1.85)
	for x in [-.92,.92]:beam(Vector3(.055,1.17,.055),Vector3(x,.62,0))
	beam(Vector3(2.03,.075,.10),Vector3(0,1.12,0))
	beam(Vector3(1.86,.045,.05),Vector3(0,.38,.08))
	for i in 5:
		var x=(i-2)*.36
		var body=paddle(Vector3(x,1.12,0),Catalog.polygon("rack"),"fall",Vector3(0,.19,0))
		# Embed the stem behind the face; matching front planes would z-fight.
		Geo.box(body,Vector3(.038,.12,.012),Vector3(0,-.13,-.010),Mat.surface("steel"))
		Geo.rod(self,Vector3(x-.08,1.10,0),Vector3(x+.08,1.10,0),.023,Mat.surface("steel"))

func tree() -> void:
	foot(.74)
	beam(Vector3(.065,1.81,.07),Vector3(0,.96,0))
	Geo.rod(support,Vector3(0,.08,-.35),Vector3(0,.62,0),.025,Mat.surface("steel"))
	for i in 6:
		var side=-1 if i%2==0 else 1
		var height=.57+i*.215
		var body=paddle(Vector3(0,height,.065),Catalog.polygon("tree"),"flip",Vector3(side*.34,0,0))
		Geo.box(body,Vector3(.22,.028,.022),Vector3(-side*.20,0,-.015),Mat.surface("steel"))
		Geo.rod(self,Vector3(0,height-.03,.065),Vector3(0,height+.03,.065),.034,Mat.surface("steel"))

func on_struck(point: Vector3, _normal: Vector3, item: Dictionary) -> void:
	if editing:return
	hits+=1
	var local=item.body.to_local(point)
	var event=Rules.classify(kind,local)
	points+=event.points
	hit.emit(self,event)
	if item.mode=="paper":return
	if item.tween and item.tween.is_valid():item.tween.kill()
	var pivot=item.pivot as Node3D
	var tween=create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	item.tween=tween
	if item.mode=="swing":
		tween.tween_property(pivot,"rotation:x",-.18,.08)
		for angle in [.13,-.09,.055,-.025,0.0]:
			tween.tween_property(pivot,"rotation:x",angle,.19).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	elif item.mode=="fall":
		tween.tween_property(pivot,"rotation:x",-PI*.46,.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		recover(item,.22)
	else:
		item.side=not item.side
		tween.tween_property(pivot,"rotation:y",PI if item.side else 0.0,.27).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		recover(item,.27)

func recover(item: Dictionary, reaction_time: float) -> void:
	# Reuse the per-paddle tween so another hit/reset cancels stale recovery.
	var tween=item.tween as Tween
	tween.tween_interval(AUTO_RESET_SECONDS-reaction_time)
	tween.tween_property(item.pivot,"rotation",item.rest,.30).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():item.side=false)

func reset() -> void:
	hits=0
	points=0
	for body in bodies:
		if body.has_method("reset"):body.reset()
	for item in paddles:
		if item.tween and item.tween.is_valid():item.tween.kill()
		item.pivot.rotation=item.rest
		item.side=false

func set_editing(value: bool) -> void:
	editing=value
	if value:reset()
	for body in bodies:
		if body is HitBody:body.editing=value

func highlight(value: bool, valid=true) -> void:
	indicator.visible=value
	indicator.material_override.albedo_color=Color(.8,.66,.32) if valid else Color(.9,.24,.16)

func rids() -> Array[RID]:
	var list: Array[RID]=[]
	for body in bodies:list.append(body.get_rid())
	return list

func record() -> Dictionary:
	return {"kind":kind,"uid":uid,"position":[global_position.x,global_position.y,global_position.z],"yaw":rotation.y}
