extends SceneTree
const Rules=preload("res://mods/ShootingRange/ScoreRules.gd")
const Session=preload("res://mods/ShootingRange/Session.gd")
const Store=preload("res://mods/ShootingRange/LayoutStore.gd")
var count=0
var failures=0
var popups=[]
var completion={}
func _initialize() -> void:
	var store=Store.new()
	store.config=ConfigFile.new()
	store.path="user://scores-test.cfg"
	var session=Session.new()
	session.store=store
	session.encouragement.connect(func(title,detail):popups.append([title,detail]))
	session.completed.connect(func(result):completion=result)
	check(Rules.classify("bullseye",Vector3.ZERO).points==100,"bullseye centre is 100 points")
	check(Rules.classify("bullseye",Vector3(.13,0,0)).points==50,"bullseye fifth ring is 50 points")
	check(Rules.classify("bullseye",Vector3(.30,0,0)).points==0,"outside scoring rings is zero")
	for kind in ["silhouette","torso"]:
		check(Rules.classify(kind,Vector3(0,.28,0)).zone=="HEADSHOT","head zone / "+kind)
		check(Rules.classify(kind,Vector3(0,-.04,0)).points==100,"centre mass is 100 / "+kind)
		check(Rules.classify(kind,Vector3(.17,-.22,0)).points==50,"body is 50 / "+kind)
	check(Rules.classify("silhouette",Vector3(.30,.30,0)).points==10,"paper outside body is 10")
	check(Rules.classify("gong",Vector3.ZERO).points==100,"steel centre is 100")
	check(Rules.classify("gong",Vector3(.1,0,0)).points==50,"steel outer is 50")
	check(Rules.classify("no_shoot",Vector3.ZERO).points==-50,"no-shoot penalty")
	for kind in ["bullseye","gong","square","diamond","rack","tree"]:
		for point in [Vector3.ZERO,Vector3(0,.28,0)]:
			check(Rules.classify(kind,point).zone!="HEADSHOT","non-human target cannot produce HEADSHOT / "+kind)
	var rows=[{"kind":"gong","position":[1.0,0.01,3.0],"yaw":0.0,"uid":"a"}]
	session.start(30,"Village",rows)
	for i in 100:session.register(Rules.classify("torso",Vector3(0,.28,0)))
	check(popups.size()==1,"rapid hits cannot flood popups after GO")
	session.tick(6,false)
	session.register(Rules.classify("torso",Vector3(0,.28,0)))
	check(popups.size()==2,"cooldown permits one encouragement after six seconds")
	check(session.total==10100 and session.headshots==101,"all hits still score during popup cooldown")
	var remaining=session.remaining
	session.tick(10,true)
	check(session.remaining==remaining,"blocked gameplay pauses round clock")
	session.tick(remaining,false)
	check(completion.new_best and store.best(session.course)==10100,"completed round saves a genuine new high score")
	var key=session.course
	session.start(30,"Village",rows)
	session.register(Rules.classify("gong",Vector3.ZERO))
	session.tick(30,false)
	check(not completion.new_best and session.best==10100,"lower score does not announce a high score")
	check(Session.course_key("Village",rows,60)!=key,"round durations keep separate records")
	var moved=rows.duplicate(true)
	moved[0].position[0]=2.0
	check(Session.course_key("Village",moved,30)!=key,"modified courses keep separate records")
	var clone=rows.duplicate(true)
	clone[0].uid="different"
	check(Session.course_key("Village",clone,30)==key,"cloned identical layout keeps its record")
	session.start(30,"Village",rows)
	session.register(Rules.classify("gong",Vector3.ZERO))
	session.abandon()
	session.tick(40,false)
	check(store.best(key)==10100,"abandoned round does not save a record")
	session.free_practice()
	session.register(Rules.classify("no_shoot",Vector3.ZERO))
	check(session.total==0,"practice total never becomes negative")
	var restored=ConfigFile.new()
	restored.load(store.path)
	check(restored.get_value("records",key)==10100,"high score survives file reload")
	print("SCORE_TESTS_COMPLETE checks=",count," failures=",failures)
	quit(1 if failures else 0)
func check(ok: bool, message: String) -> void:
	count+=1
	if not ok:failures+=1
	print("CHECK ","PASS " if ok else "FAIL ",message)
