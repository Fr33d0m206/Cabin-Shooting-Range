extends StaticBody3D
## Observe the real weapon's impact effect, preserving native raycasts/audio.
signal struck(point: Vector3, normal: Vector3)
var surface="Metal"
var range_target: Node3D
var editing=false
var marks: Array[MeshInstance3D]=[]
const Mat=preload("res://mods/ShootingRange/Materials.gd")
func _ready() -> void:
	collision_layer=1
	collision_mask=0
	child_entered_tree.connect(observe_effect)
func observe_effect(child: Node) -> void:
	if not editing and child.scene_file_path=="res://Effects/Hit_Default.tscn":
		if Engine.get_meta("RangeShotFilter",false) and not Engine.get_meta("RangePlayerShot",false):return
		record_effect.call_deferred(weakref(child))
func record_effect(reference: WeakRef) -> void:
	var effect=reference.get_ref() as Node3D
	if not is_instance_valid(effect) or editing:return
	# Native HitEffect places/orients the child immediately after add_child().
	register_hit(effect.global_position,-effect.global_basis.z.normalized())
func register_hit(point: Vector3, normal: Vector3) -> void:
	if editing:return
	var mark=MeshInstance3D.new()
	var quad=QuadMesh.new()
	quad.size=Vector2(.026,.026)
	mark.mesh=quad
	mark.material_override=Mat.impact()
	mark.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mark)
	mark.global_position=point+normal*.0015
	mark.look_at(mark.global_position+normal,Vector3.RIGHT if absf(normal.y)>.95 else Vector3.UP,true)
	marks.append(mark)
	if marks.size()>48:marks.pop_front().queue_free()
	struck.emit(point,normal)
func reset() -> void:
	for mark in marks:
		if is_instance_valid(mark):mark.queue_free()
	marks.clear()
