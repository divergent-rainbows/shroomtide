extends Resource
class_name SaveData

@export var energy: float
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
		
