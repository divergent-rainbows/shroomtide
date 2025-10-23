extends Resource
class_name LevelSaveData

## Save data for the player's progress on the current level

@export var id: String
@export var run_time: float = 0.0
@export var energy_g: float
@export var plants_map: Dictionary[Vector2i, PlantData] = {}
@export var network_paths: Array[Array] = []
@export var plants: Array[PlantData] = []
@export var coords: Vector2 = Vector2.ZERO

static func create_from_level(level) -> LevelSaveData:
	var new_save_data = LevelSaveData.new()
	var new_plants := {} as Dictionary[Vector2i, PlantData]
	for plant_type in Global.PlantType.values():
		var starting_tiles = level.plant_locations[plant_type]
		for i in range(starting_tiles.size()):
			var pd = PlantData.create_from_type(plant_type)
			new_plants[starting_tiles[i]] = pd
	new_save_data.upload_plants(new_plants)
	return new_save_data

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

func print_to_console() -> void:
	print("Level: ", id)
	print("Energy: ", energy_g)
	print(serialize_plant_data())
