extends Resource
class_name LevelData

## Contains the plant locations for each type of plant in the level

@export var id : int
@export var name: String
@export var starting_energy : int = 100
@export var plant_locations : Dictionary[Global.PlantType, Array]

func print_to_console() -> void: 
	print('Level: ', id, '-', name)
	print('Starting energy: ', starting_energy)
	print('Plant locations: ', plant_locations)
