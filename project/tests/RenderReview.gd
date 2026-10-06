extends SceneTree
const Target=preload("res://mods/ShootingRange/Target.gd")
const Catalog=preload("res://mods/ShootingRange/Catalog.gd")
const Geo=preload("res://mods/ShootingRange/Geometry.gd")
const UI=preload("res://mods/ShootingRange/Main.gd")
var world: Node3D
var camera: Camera3D
func _initialize() -> void:run.call_deferred()
func run() -> void:
	world=Node3D.new()
	world.name="Map"
	root.add_child(world)
	var environment=WorldEnvironment.new()
	var env=Environment.new()
	env.background_mode=Environment.BG_SKY
	var sky=Sky.new()
	var sky_material=ProceduralSkyMaterial.new()
	sky_material.sky_top_color=Color(.22,.32,.35)
	sky_material.sky_horizon_color=Color(.62,.65,.58)
	sky_material.ground_bottom_color=Color(.10,.12,.10)
	sky_material.ground_horizon_color=Color(.43,.44,.35)
	sky.sky_material=sky_material
	env.sky=sky
	env.ambient_light_source=Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy=.65
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	environment.environment=env
	world.add_child(environment)
	var sun=DirectionalLight3D.new()
	world.add_child(sun)
	sun.rotation_degrees=Vector3(-38,-35,0)
	sun.light_color=Color(1,.98,.93)
	sun.light_energy=.85
	sun.shadow_enabled=true
	var ground=StandardMaterial3D.new()
	ground.albedo_color=Color(.17,.19,.145)
	ground.roughness=.97
	Geo.box(world,Vector3(100,.1,100),Vector3(0,-.055,0),ground)
	var kinds=Catalog.TYPES.keys()
	for i in kinds.size():
		var target=Target.new()
		target.kind=kinds[i]
		target.uid=str(i)
		world.add_child(target)
		target.position=Vector3((i%4-1.5)*2.8,.0,-floorf(i/4.0)*3.0)
	camera=Camera3D.new()
	world.add_child(camera)
	camera.position=Vector3(6.5,7.6,15)
	camera.fov=42
	camera.look_at(Vector3(0,1,-3.0))
	camera.make_current()
	var overlay=CanvasLayer.new()
	world.add_child(overlay)
	var title=Label.new()
	title.text="V O S T O K    /    C A B I N   R A N G E\nORIGINAL TARGET COLLECTION"
	title.position=Vector2(38,32)
	title.add_theme_font_size_override("font_size",22)
	title.add_theme_color_override("font_color",Color(.9,.86,.71))
	overlay.add_child(title)
	await capture("collection")
	camera.position=Vector3(.7,2.0,3.2)
	camera.look_at(Vector3(1.4,1.15,0))
	title.text="REACTIVE STEEL    /    CHIPPED PAINT + RUST + BEVELED EDGES"
	await capture("steel-detail")
	camera.position=Vector3(-3.8,1.9,2.0)
	camera.look_at(Vector3(-4.2,1.25,0))
	title.text="PRECISION PAPER    /    WORN PRINT + TIMBER + HARDWARE"
	await capture("paper-detail")
	for kind in ["rack","tree"]:
		var target=world.get_children().filter(func(node):return node is Target and node.kind==kind)[0]
		var face=target.paddles[0].body as Node3D
		title.text=kind.to_upper()+"    /    RECESSED PADDLE ATTACHMENT"
		camera.position=face.global_position+Vector3(.13,-.035,.55)
		camera.look_at(face.global_position+Vector3(0,-.045,0))
		await capture(kind+"-joint-front")
		camera.position=face.global_position+Vector3(.13,-.035,-.55)
		camera.look_at(face.global_position+Vector3(0,-.045,0))
		await capture(kind+"-joint-back")
	for kind in ["gong","torso"]:
		var target=world.get_children().filter(func(node):return node is Target and node.kind==kind)[0]
		var focus=target.global_position+Vector3(0,1.48,0)
		camera.position=focus+Vector3(.34,.08,1.05)
		camera.look_at(focus)
		title.text=kind.to_upper()+"    /    LINKED CHAINS + PLATE MOUNTS"
		await capture(kind+"-chain-rest")
		var item=target.paddles[0]
		item.body.register_hit(item.body.global_position,Vector3.BACK)
		item.tween.pause()
		item.tween.custom_step(.08)
		title.text=kind.to_upper()+"    /    ATTACHMENTS AT SWING PEAK"
		await capture(kind+"-chain-swing")
		target.reset()
	camera.position=Vector3(4,5.3,11)
	camera.look_at(Vector3(0,.8,-1))
	title.hide()
	var host=UI.new()
	root.add_child(host)
	host.set_process(false)
	host.active_map=world
	host.root=Node3D.new()
	world.add_child(host.root)
	var core=Node3D.new()
	core.name="Core"
	world.add_child(core)
	host.editor.open()
	await capture("editor")
	host.editor.close()
	root.size=Vector2i(1280,720)
	host.editor.open()
	await capture("editor-720")
	host.editor.close()
	root.size=Vector2i(1600,1000)
	host.feedback.set_enabled(true)
	host.session.free_practice()
	host.session.register({"points":100,"zone":"HEADSHOT","strong":true})
	await capture("score-headshot")
	host.session.start(60,"Preview",[{"kind":"gong","position":[1,0,3],"yaw":0,"uid":"preview"}])
	host.session.total=host.session.best+850
	host.session.hits=11
	host.session.headshots=3
	host.session.tick(60,false)
	await capture("score-high-score")
	host.queue_free()
	world.queue_free()
	await process_frame
	print("RANGE_RENDER_COMPLETE")
	quit()
func capture(name: String) -> void:
	await create_timer(.3).timeout
	await RenderingServer.frame_post_draw
	var output="res://../validation/"+name+"-"+RenderingServer.get_current_rendering_method()+".png"
	root.get_texture().get_image().save_png(output)
	print("RANGE_CAPTURE ",output)
