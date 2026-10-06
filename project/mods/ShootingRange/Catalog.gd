extends RefCounted
## Dimensions are metres. All geometry uses shared baked materials.
const TYPES = {
	"bullseye": {"name":"Paper bullseye", "detail":"Scoring rings / timber frame", "size":Vector3(.85,1.85,.75)},
	"silhouette": {"name":"Paper silhouette", "detail":"A-zone / weathered backer", "size":Vector3(.85,1.85,.75)},
	"torso": {"name":"Steel torso", "detail":"Beveled plate / hanging chains", "size":Vector3(1.2,1.8,.85)},
	"gong": {"name":"Round gong", "detail":"300 mm / reactive steel", "size":Vector3(1.2,1.8,.85)},
	"square": {"name":"Square plate", "detail":"300 mm / reactive steel", "size":Vector3(1.2,1.8,.85)},
	"diamond": {"name":"Diamond plate", "detail":"Precision / reactive steel", "size":Vector3(1.2,1.8,.85)},
	"rack": {"name":"Five-plate rack", "detail":"Falling paddles / resettable", "size":Vector3(2.1,1.45,.85)},
	"tree": {"name":"Dueling tree", "detail":"Six flipping paddles / resettable", "size":Vector3(1.1,1.9,.85)},
	"no_shoot": {"name":"No-shoot silhouette", "detail":"Precision discipline / -50 penalty", "size":Vector3(.85,1.85,.75)},
	"wall": {"name":"Practice wall", "detail":"Modular plywood / build rooms", "size":Vector3(2.2,2.4,.85)},
	"doorway": {"name":"Practice doorway", "detail":"Open passage / modular rooms", "size":Vector3(2.2,2.4,.85)},
	"window": {"name":"Practice window", "detail":"Sightline cutout / modular rooms", "size":Vector3(2.2,2.4,.85)}
}
static func price(kind: String) -> int:
	return {"bullseye":25,"silhouette":30,"no_shoot":30,"gong":75,"square":70,"diamond":70,"torso":100,"rack":180,"tree":200,"wall":80,"doorway":90,"window":90}.get(kind,50)
static func polygon(kind: String) -> PackedVector2Array:
	var p=PackedVector2Array()
	if kind=="gong" or kind=="rack" or kind=="tree":
		var radius=.15 if kind=="gong" else .10
		for i in 48:
			p.append(Vector2(cos(TAU*i/48),sin(TAU*i/48))*radius)
	elif kind=="torso":
		p=PackedVector2Array([Vector2(-.23,-.40),Vector2(.23,-.40),Vector2(.23,.14),Vector2(.12,.24),Vector2(.10,.40),Vector2(-.10,.40),Vector2(-.12,.24),Vector2(-.23,.14)])
	elif kind=="diamond":
		p=PackedVector2Array([Vector2(0,-.23),Vector2(.23,0),Vector2(0,.23),Vector2(-.23,0)])
	else:
		p=PackedVector2Array([Vector2(-.15,-.15),Vector2(.15,-.15),Vector2(.15,.15),Vector2(-.15,.15)])
	return p
