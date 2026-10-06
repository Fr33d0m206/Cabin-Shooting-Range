extends RefCounted
const Catalog=preload("res://mods/ShootingRange/Catalog.gd")
var space: PhysicsDirectSpaceState3D
var excluded: Array[RID]=[]
var max_distance=100.0
var anchor=Vector3.ZERO

func floor_at(point: Vector3) -> Dictionary:
	var query=PhysicsRayQueryParameters3D.create(point+Vector3.UP*2.5,point-Vector3.UP*4,0x7FFFFFFF,excluded)
	var found=space.intersect_ray(query)
	if found.is_empty() or found.normal.y<.94:return {}
	# Never stand on another target, vehicle, furniture or actor.
	var body=found.collider
	if body is CharacterBody3D or body is RigidBody3D or body.has_meta("range_target"):return {}
	return found

func evaluate(point: Vector3, kind: String, yaw: float, own: Array[RID]=[]) -> Dictionary:
	if not Catalog.TYPES.has(kind):return {"valid":false,"reason":"Unknown target"}
	if Vector2(point.x-anchor.x,point.z-anchor.z).length()>max_distance:
		return {"valid":false,"reason":"Beyond this map's placement bounds"}
	var size: Vector3=Catalog.TYPES[kind].size
	var basis=Basis(Vector3.UP,yaw)
	var original=excluded.duplicate()
	excluded.append_array(own)
	var highest=-INF
	var lowest=INF
	for offset in [Vector3.ZERO,Vector3(-size.x*.48,0,-size.z*.45),Vector3(size.x*.48,0,-size.z*.45),Vector3(-size.x*.48,0,size.z*.45),Vector3(size.x*.48,0,size.z*.45)]:
		var floor=floor_at(point+basis*offset)
		if floor.is_empty():
			excluded.assign(original)
			return {"valid":false,"reason":"Needs firm, level ground under all feet"}
		highest=maxf(highest,floor.position.y)
		lowest=minf(lowest,floor.position.y)
	excluded.assign(original)
	if highest-lowest>.12:return {"valid":false,"reason":"Ground is too uneven"}
	var origin=Vector3(point.x,highest+.01,point.z)
	var hull=BoxShape3D.new()
	hull.size=Vector3(size.x,size.y-.18,size.z)
	var query=PhysicsShapeQueryParameters3D.new()
	query.shape=hull
	query.transform=Transform3D(basis,origin+Vector3.UP*(size.y*.5+.09))
	query.collision_mask=0x7FFFFFFF
	query.exclude=own+excluded
	if not space.intersect_shape(query,1).is_empty():return {"valid":false,"reason":"Blocked by a target, tree, wall or player"}
	return {"valid":true,"position":origin,"reason":"Ready to place"}

func cursor(camera: Camera3D, point: Vector2, ignore: Array[RID]) -> Dictionary:
	var origin=camera.project_ray_origin(point)
	var query=PhysicsRayQueryParameters3D.create(origin,origin+camera.project_ray_normal(point)*300,0x7FFFFFFF,ignore+excluded)
	return space.intersect_ray(query)
