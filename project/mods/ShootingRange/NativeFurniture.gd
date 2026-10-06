extends "res://Scripts/Furniture.gd"
## Keep native Catalog/Placer behavior; range meshes have their own exact bodies.
var target: Node3D
var host: Node
var old_layers: Array[int]=[]
func _ready() -> void:
	super._ready()
	target=get_parent()
	host=get_node_or_null("/root/ShootingRangeMain")
	attach.call_deferred()
func attach() -> void:
	var bound=colliderR.get_child(0)
	if not target.bodies.has(bound):target.bodies.append(bound)
	for body in target.bodies:
		body.owner=target
		body.set_meta("range_target",target)
		body.add_to_group("Furniture")
	if host:host.furniture_bridge.adopt(target)
func StartMove() -> void:
	# Catalog placement can begin before the deferred ready attachment.
	attach()
	super.StartMove()
	if host:host.session.abandon()
	target.set_editing(true)
	old_layers.clear()
	for body in target.bodies:
		old_layers.append(body.collision_layer)
		body.collision_layer=0
	target.highlight(true)
func ResetMove() -> void:
	super.ResetMove()
	for i in target.bodies.size():target.bodies[i].collision_layer=old_layers[i] if i<old_layers.size() else 1
	old_layers.clear()
	target.set_editing(false)
	target.highlight(false)
	if host:host.furniture_bridge.committed(target)
func CanPlace() -> bool:
	var valid=super.CanPlace()
	if is_instance_valid(target) and isMoving:target.highlight(true,valid)
	return valid
func Catalog() -> void:
	if host and host.targets.has(target):
		host.targets.erase(target)
		host.dirty=true
		host.save_working()
	super.Catalog()
