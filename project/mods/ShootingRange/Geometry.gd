extends RefCounted
## Thin plates have beveled edges and exact polygon collision, including corners.
const Mat=preload("res://mods/ShootingRange/Materials.gd")
static func box(parent: Node3D, size: Vector3, point: Vector3, material: Material) -> MeshInstance3D:
	var node=MeshInstance3D.new()
	var mesh=BoxMesh.new()
	mesh.size=size
	node.mesh=mesh
	node.material_override=material
	parent.add_child(node)
	node.position=point
	return node
static func rod(parent: Node3D, a: Vector3, b: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var node=MeshInstance3D.new()
	var mesh=CylinderMesh.new()
	mesh.top_radius=radius
	mesh.bottom_radius=radius
	mesh.height=a.distance_to(b)
	mesh.radial_segments=12
	node.mesh=mesh
	node.material_override=material
	parent.add_child(node)
	node.position=(a+b)*.5
	var up=(b-a).normalized()
	var right=up.cross(Vector3.FORWARD).normalized()
	if right.length_squared()<.1:right=Vector3.RIGHT
	node.basis=Basis(right,up,right.cross(up)).orthonormalized()
	return node
static func plate(parent: Node3D, polygon: PackedVector2Array, depth: float) -> Shape3D:
	var tool=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var indices=Geometry2D.triangulate_polygon(polygon)
	var inner=PackedVector2Array()
	for point in polygon:
		inner.append(point*.98)
	for side in [-1.0,1.0]:
		for i in range(0,indices.size(),3):
			for j in ([2,1,0] if side>0 else [0,1,2]):
				var p=inner[indices[i+j]]
				tool.set_normal(Vector3(0,0,side))
				tool.set_uv(p+Vector2(.5,.5))
				tool.add_vertex(Vector3(p.x,p.y,depth*.5*side))
	for i in polygon.size():
		var next=(i+1)%polygon.size()
		var a=polygon[i]
		var b=polygon[next]
		for side in [-1.0,1.0]:
			var outer_a=Vector3(a.x,a.y,side*(depth*.5-.003))
			var outer_b=Vector3(b.x,b.y,side*(depth*.5-.003))
			var inner_a=Vector3(inner[i].x,inner[i].y,side*depth*.5)
			var inner_b=Vector3(inner[next].x,inner[next].y,side*depth*.5)
			tri(tool,outer_a,inner_a,inner_b)
			tri(tool,outer_a,inner_b,outer_b)
		tri(tool,Vector3(a.x,a.y,-depth*.5+.003),Vector3(a.x,a.y,depth*.5-.003),Vector3(b.x,b.y,depth*.5-.003))
		tri(tool,Vector3(a.x,a.y,-depth*.5+.003),Vector3(b.x,b.y,depth*.5-.003),Vector3(b.x,b.y,-depth*.5+.003))
	var mesh=MeshInstance3D.new()
	mesh.mesh=tool.commit()
	mesh.material_override=Mat.surface("paint")
	# Edge triangles have explicit flat normals, so bevels catch light.
	mesh.material_override.cull_mode=BaseMaterial3D.CULL_DISABLED
	parent.add_child(mesh)
	var shape=mesh.mesh.create_trimesh_shape()
	shape.backface_collision=true
	return shape
static func tri(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var normal=(b-a).cross(c-a).normalized()
	for point in [a,b,c]:
		tool.set_normal(normal)
		tool.set_uv(Vector2(point.x,point.y))
		tool.add_vertex(point)
static func collider(parent: StaticBody3D, shape: Shape3D) -> void:
	var node=CollisionShape3D.new()
	node.shape=shape
	parent.add_child(node)
static func chain(parent: Node3D, x: float, top: float, bottom: float) -> Node3D:
	var chain_root=Node3D.new()
	parent.add_child(chain_root)
	chain_root.position=Vector3(x,top,0)
	var ring=TorusMesh.new()
	ring.inner_radius=.008
	ring.outer_radius=.015
	ring.rings=8
	ring.ring_segments=6
	var material=Mat.surface("steel")
	# Include both attachment ends; overlapping alternating links interlock.
	var steps=maxi(1,ceili(absf(top-bottom)/.028))
	for i in steps+1:
		var node=MeshInstance3D.new()
		node.mesh=ring
		node.material_override=material
		chain_root.add_child(node)
		node.position=Vector3(0,(bottom-top)*float(i)/steps,0)
		node.rotation=Vector3(PI*.5,PI*.5*(i%2),0)
		node.scale=Vector3(1,1,1.4)
	return chain_root
