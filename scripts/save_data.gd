extends Resource
class_name SaveData

@export var energy_g: float # Glycosine
@export var energy_a: float # Alkaloid
@export var energy_p: float # Polyphenols
@export var energy_t: float # Terpenes
@export var plants_map: Dictionary[Vector2i, PlantData]
@export var plants: Array[PlantData]
@export var coords: Vector2

func upload_plants(dict: Dictionary[Vector2i, PlantData]):
	plants_map = dict
	plants = dict.values()
	for i in range(plants.size()):
		plants[i].id = i

func serialize_plant_data() -> Dictionary:
	var result := {}
	for key in plants_map.keys():
		var value = plants_map[key]
		if value is PlantData:
			result[key] = value.stringify_type()
		else:
			result[key] = value
	return result
		
