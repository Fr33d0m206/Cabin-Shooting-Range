extends RefCounted
signal changed
signal encouragement(title: String, detail: String)
signal completed(summary: Dictionary)
var store: RefCounted
var mode="free"
var total=0
var hits=0
var headshots=0
var strong_streak=0
var remaining=0.0
var duration=60
var course=""
var best=0
var cooldown=0.0
var since_notice=0
var elapsed=0.0

func free_practice() -> void:
	clear()
	mode="free"
	changed.emit()
func clear() -> void:
	total=0
	hits=0
	headshots=0
	strong_streak=0
	cooldown=0
	since_notice=0
	elapsed=0
func start(seconds: int, map_key: String, rows: Array) -> void:
	clear()
	duration=clampi(seconds,30,180)
	remaining=duration
	mode="timed"
	course=course_key(map_key,rows,duration)
	best=store.best(course)
	encouragement.emit("GO!",str(duration)+" SECOND CHALLENGE")
	cooldown=3.5
	changed.emit()
func tick(delta: float, paused: bool) -> void:
	if paused:return
	elapsed+=delta
	cooldown=maxf(0,cooldown-delta)
	if mode=="timed":
		remaining=maxf(0,remaining-delta)
		if remaining==0:finish()
func register(event: Dictionary) -> void:
	if mode=="complete":return
	total=maxi(0,total+int(event.points))
	hits+=1
	if event.zone=="HEADSHOT":headshots+=1
	strong_streak=strong_streak+1 if event.strong else 0
	since_notice+=1
	if cooldown<=0 and (event.zone in ["HEADSHOT","BULLSEYE","NO SHOOT"] or since_notice>=5):
		var title=event.zone
		if strong_streak>=5:title="EPIC!" if strong_streak<10 else "ON FIRE!"
		elif since_notice>=5 and event.zone not in ["HEADSHOT","BULLSEYE","NO SHOOT"]:title="NICE SHOT" if event.strong else "KEEP IT GOING"
		encouragement.emit(title,("+" if event.points>=0 else "")+str(event.points)+" POINTS")
		cooldown=5.5
		since_notice=0
	changed.emit()
func finish() -> void:
	if mode!="timed":return
	mode="complete"
	var new_best=total>best and store.save_best(course,total)
	if new_best:best=total
	completed.emit({"points":total,"hits":hits,"headshots":headshots,"best":best,"new_best":new_best})
	changed.emit()
func abandon() -> void:
	if mode=="timed":
		mode="complete"
		changed.emit()
static func course_key(map_key: String, rows: Array, seconds: int) -> String:
	var pieces: Array[String]=[]
	for row in rows:
		pieces.append("%s:%.2f:%.2f:%.2f:%.2f" % [row.kind,row.position[0],row.position[1],row.position[2],row.yaw])
	pieces.sort()
	return ("rules1:"+map_key+":"+str(seconds)+":"+"|".join(pieces)).sha256_text()
