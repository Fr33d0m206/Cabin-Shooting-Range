"""Author small native furniture scenes/data, without copying native game art."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]/'project'
OUT=ROOT/'Assets/ShootingRange';OUT.mkdir(parents=True,exist_ok=True)
specs={
 'bullseye':('Paper Bullseye',.85,1.85,.75,25),'silhouette':('Paper Silhouette',.85,1.85,.75,30),
 'no_shoot':('No-Shoot Silhouette',.85,1.85,.75,30),'torso':('Steel Torso',1.2,1.8,.85,100),
 'gong':('Round Gong',1.2,1.8,.85,75),'square':('Square Plate',1.2,1.8,.85,70),
 'diamond':('Diamond Plate',1.2,1.8,.85,70),'rack':('Five-Plate Rack',2.1,1.45,.85,180),
 'tree':('Dueling Tree',1.1,1.9,.85,200),'wall':('Practice Wall',2.2,2.4,.85,80),
 'doorway':('Practice Doorway',2.2,2.4,.85,90),'window':('Practice Window',2.2,2.4,.85,90)}
for kind,(label,w,h,d,price) in specs.items():
    base=f'res://Assets/ShootingRange/{kind}_F'
    (OUT/f'{kind}_Icon.tscn').write_text(f'''[gd_scene format=3]
[ext_resource type="Script" path="res://mods/ShootingRange/ItemIcon.gd" id="1"]
[node name="RangeIcon" type="Sprite2D"]
position = Vector2(64, 64)
script = ExtResource("1")
kind = "{kind}"
''')
    (OUT/f'{kind}_F.tres').write_text(f'''[gd_resource type="Resource" script_class="ItemData" format=3]
[ext_resource type="Script" path="res://Scripts/ItemData.gd" id="1"]
[ext_resource type="PackedScene" path="res://Assets/ShootingRange/{kind}_Icon.tscn" id="2"]
[resource]
script = ExtResource("1")
file = "ShootingRange_{kind}"
name = "Range: {label}"
display = "Range: {label}"
inventory = "Range: {label}"
rotated = "Range: {label}"
equipment = "Range: {label}"
type = "Furniture"
subtype = "Practice Range"
size = Vector2(2, 2)
value = {price}
weight = 0.0
rarity = 0
generalist = true
stackable = false
tetris = ExtResource("2")
''')
    scene=f'''[gd_scene format=3]
[ext_resource type="Script" path="res://mods/ShootingRange/Target.gd" id="1"]
[ext_resource type="Script" path="res://mods/ShootingRange/NativeFurniture.gd" id="2"]
[ext_resource type="Resource" path="{base}.tres" id="3"]
[ext_resource type="Texture2D" path="res://UI/Sprites/Icon_Object.png" id="4"]
[ext_resource type="Material" path="res://Modular/Materials/MT_Hint.tres" id="5"]
[sub_resource type="BoxMesh" id="Bounds"]
size = Vector3({w}, {h}, {d})
custom_aabb = AABB({-w/2}, 0, {-d/2}, {w}, {h}, {d})
[sub_resource type="BoxShape3D" id="Feet"]
size = Vector3(0.1, 0.06, 0.6)
[sub_resource type="BoxShape3D" id="Area"]
size = Vector3({w-.10}, {h-.20}, {d-.10})
[sub_resource type="BoxShape3D" id="Parent"]
size = Vector3({w+.10}, {h+.10}, {d+.10})
[sub_resource type="PlaneMesh" id="Hint"]
material = ExtResource("5")
size = Vector2({w}, {d})
[node name="Range_{kind}_F" type="Node3D"]
script = ExtResource("1")
kind = "{kind}"
[node name="Bounds" type="MeshInstance3D" parent="."]
visible = false
mesh = SubResource("Bounds")
[node name="Body" type="StaticBody3D" parent="Bounds" groups=["Furniture"]]
collision_layer = 1
collision_mask = 0
[node name="Shape" type="CollisionShape3D" parent="Bounds/Body"]
position = Vector3(0, 0.04, 0)
shape = SubResource("Feet")
[node name="Furniture" type="Node3D" parent="." node_paths=PackedStringArray("mesh", "colliderR")]
script = ExtResource("2")
itemData = ExtResource("3")
mesh = NodePath("../Bounds")
colliderR = NodePath("../Bounds")
[node name="Indicator" type="Sprite3D" parent="Furniture"]
modulate = Color(0.7, 0.85, 0.5, 0.4)
texture = ExtResource("4")
pixel_size = 0.0005
billboard = 1
no_depth_test = true
[node name="Area" type="Area3D" parent="Furniture"]
collision_layer = 0
collision_mask = 8255
[node name="Shape" type="CollisionShape3D" parent="Furniture/Area"]
position = Vector3(0, {h/2+.1}, 0)
shape = SubResource("Area")
[node name="Parenter" type="Area3D" parent="Furniture"]
collision_layer = 0
collision_mask = 4
[node name="Shape" type="CollisionShape3D" parent="Furniture/Parenter"]
position = Vector3(0, {h/2}, 0)
shape = SubResource("Parent")
[node name="Rays" type="Node3D" parent="Furniture"]
'''
    for i,(x,z) in enumerate([(0,0),(w*.45,d*.40),(-w*.45,d*.40),(w*.45,-d*.40),(-w*.45,-d*.40)]):
        scene+=f'''[node name="Ray_{i}" type="RayCast3D" parent="Furniture/Rays"]
position = Vector3({x}, 0.12, {z})
target_position = Vector3(0, -0.3, 0)
enabled = false
'''
    scene+='''[node name="Hint" type="MeshInstance3D" parent="Furniture"]
mesh = SubResource("Hint")
'''
    (OUT/f'{kind}_F.tscn').write_text(scene)
print(f'Authored {len(specs)} native furniture bundles')
