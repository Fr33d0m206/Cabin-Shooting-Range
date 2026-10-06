extends RefCounted
## Arcade points retain conventional concentric ring order (ten-ring = 100).
static func classify(kind: String, local: Vector3) -> Dictionary:
	var p=Vector2(local.x,local.y)
	if kind=="no_shoot":return {"points":-50,"zone":"NO SHOOT","strong":false}
	if kind=="bullseye":
		var ring=clampi(10-int(Vector2(p.x,p.y+.007).length()/.0242),0,10)
		return {"points":ring*10,"zone":"BULLSEYE" if ring==10 else str(ring)+" RING" if ring>0 else "OUTER","strong":ring>=8}
	if kind=="silhouette" or kind=="torso":
		var head=absf(p.x)<(.078 if kind=="silhouette" else .105) and p.y>(.16 if kind=="silhouette" else .24) and p.y<(.31 if kind=="silhouette" else .41)
		if head:return {"points":100,"zone":"HEADSHOT","strong":true}
		var centre=Vector2(0,-.045) if kind=="silhouette" else Vector2(0,-.02)
		var central=absf(p.x)<(.075 if kind=="silhouette" else .11) and absf(p.y-centre.y)<(.10 if kind=="silhouette" else .14)
		if central:return {"points":100,"zone":"CENTER MASS","strong":true}
		var body=absf(p.x)<.19 and p.y>-.31 and p.y<.16 if kind=="silhouette" else true
		return {"points":50 if body else 10,"zone":"BODY SHOT" if body else "OUTER","strong":false}
	var radius=.045 if kind in ["gong","square","diamond"] else .03
	var centre=p.length()<radius
	return {"points":100 if centre else 50,"zone":"DEAD CENTER" if centre else "STEEL HIT","strong":centre}
