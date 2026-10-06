extends Sprite2D
const Mat=preload("res://mods/ShootingRange/Materials.gd")
@export var kind="gong"
func _enter_tree() -> void:
	texture=Mat.texture("icon_"+kind)
	scale=Vector2.ONE*.5
