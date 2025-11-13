extends RefCounted

static func from_dict(type: GDScript, dict: Dictionary[String, Variant]):
	var entity := type.new()
	for key: String in dict.keys():
		entity.set(key, dict[key])
	return entity

static func from_dict_array(type: GDScript, array: Array[Dictionary]) -> Array:
	if array.is_empty(): return []
	var entities: Array = []
	for dict: Dictionary in array:
		entities.append(from_dict(type, dict))
	return entities
