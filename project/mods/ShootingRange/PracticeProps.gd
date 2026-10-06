extends RefCounted
## Freestanding modular plywood walls form rooms without changing the map.
static func build(target: Node3D, kind: String) -> void:
	target.foot(1.85)
	for x in [-1.0,1.0]:target.beam(Vector3(.08,2.32,.08),Vector3(x,1.20,0),true)
	target.beam(Vector3(2.08,.10,.09),Vector3(0,2.31,0),true)
	if kind=="wall":
		for i in 4:target.beam(Vector3(.515,2.15,.032),Vector3((i-1.5)*.51,1.18,0),true)
	elif kind=="doorway":
		for x in [-.78,.78]:target.beam(Vector3(.45,2.15,.032),Vector3(x,1.18,0),true)
		target.beam(Vector3(1.13,.26,.032),Vector3(0,2.13,0),true)
	else:
		for x in [-.80,.80]:target.beam(Vector3(.42,2.15,.032),Vector3(x,1.18,0),true)
		target.beam(Vector3(1.20,.90,.032),Vector3(0,.55,0),true)
		target.beam(Vector3(1.20,.35,.032),Vector3(0,2.09,0),true)
