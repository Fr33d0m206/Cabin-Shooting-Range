extends RefCounted
const Catalog=preload("res://mods/ShootingRange/Catalog.gd")
const LIMIT=40
var path="user://cabin_shooting_range.cfg"
var config=ConfigFile.new()
var serial=0
func _init() -> void:
	config.load(path)
func valid(rows: Variant) -> bool:
	if not rows is Array or rows.size()>LIMIT:return false
	var ids={}
	for row in rows:
		if not row is Dictionary or not Catalog.TYPES.has(row.get("kind","")):return false
		var pos=row.get("position",null)
		if not pos is Array or pos.size()!=3:return false
		for axis in pos:
			if not (axis is float or axis is int) or not is_finite(float(axis)) or absf(float(axis))>10000:return false
		var yaw=row.get("yaw",null)
		if not (yaw is float or yaw is int) or not is_finite(float(yaw)):return false
		var uid=row.get("uid",null)
		if not uid is String or uid.is_empty() or uid.length()>64 or ids.has(uid):return false
		ids[uid]=true
	return true
func read(map_key: String, slot: String) -> Array:
	var rows=config.get_value(map_key,slot,[])
	return rows.duplicate(true) if valid(rows) else []
func has_layout(map_key: String) -> bool:
	return config.has_section_key(map_key,"working")
func write(map_key: String, slot: String, rows: Array) -> bool:
	if not valid(rows):return false
	var previous=config.get_value(map_key,slot) if config.has_section_key(map_key,slot) else null
	config.set_value(map_key,slot,rows.duplicate(true))
	var temporary=path+".tmp"
	if config.save(temporary)!=OK:
		restore_value(map_key,slot,previous)
		return false
	var result=DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary),ProjectSettings.globalize_path(path))
	if result!=OK:restore_value(map_key,slot,previous)
	return result==OK
func restore_value(map_key: String, slot: String, previous: Variant) -> void:
	if previous==null:config.erase_section_key(map_key,slot)
	else:config.set_value(map_key,slot,previous)
func next_id() -> String:
	serial+=1
	return str(Time.get_ticks_usec())+"_"+str(serial)
func best(key: String) -> int:
	var value=config.get_value("records",key,0)
	return maxi(0,value) if value is int else 0
func save_best(key: String, value: int) -> bool:
	if value<=best(key):return false
	var previous=best(key)
	config.set_value("records",key,value)
	var temporary=path+".tmp"
	if config.save(temporary)==OK and DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary),ProjectSettings.globalize_path(path))==OK:return true
	config.set_value("records",key,previous)
	return false
