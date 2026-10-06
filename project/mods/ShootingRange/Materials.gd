extends RefCounted
const DIR="res://mods/ShootingRange/assets/"
static var cache: Dictionary={}
static func texture(file: String) -> ImageTexture:
	if not cache.has(file):
		var source=Image.load_from_file(DIR+file+".png")
		if source==null:return null
		source.generate_mipmaps()
		cache[file]=ImageTexture.create_from_image(source)
	return cache[file]
static func surface(kind: String) -> StandardMaterial3D:
	var key="material:"+kind
	if cache.has(key):return cache[key]
	var material=StandardMaterial3D.new()
	material.albedo_texture=texture(kind+"_color")
	material.normal_enabled=true
	material.normal_texture=texture(kind+"_normal")
	material.normal_scale=.55
	material.roughness_texture=texture(kind+"_rough")
	material.roughness_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_RED
	material.roughness=1.0
	material.metallic=.72 if kind=="steel" else .08
	material.uv1_triplanar=true
	material.uv1_scale=Vector3(2,2,2) if kind!="wood" else Vector3(5,.7,5)
	cache[key]=material
	return material
static func print_material(kind: String) -> StandardMaterial3D:
	var key="print:"+kind
	if not cache.has(key):
		var material=StandardMaterial3D.new()
		material.albedo_texture=texture(kind)
		material.roughness=.96
		material.cull_mode=BaseMaterial3D.CULL_DISABLED
		cache[key]=material
	return cache[key]
static func impact() -> StandardMaterial3D:
	if not cache.has("impact-material"):
		var material=StandardMaterial3D.new()
		material.albedo_texture=texture("impact")
		material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		material.roughness=.95
		material.cull_mode=BaseMaterial3D.CULL_DISABLED
		cache["impact-material"]=material
	return cache["impact-material"]
