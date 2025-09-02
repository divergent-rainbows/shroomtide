extends Node

const GAME_SAVE_PATH = "user://save_data.tres"
var data: SaveData 

func _ready() -> void: 
	var loaded = load(GAME_SAVE_PATH)
	if loaded and loaded is SaveData:
		data = loaded
	else:
		data = SaveData.new()
		data.energy_g = 100
		ResourceSaver.save(data, GAME_SAVE_PATH)
	if data.plants.is_empty():
		World.initialize_plant_data()

func save_game():
	var err = ResourceSaver.save(data, GAME_SAVE_PATH)
	if err != OK:
		push_error("Save failed: %s" % error_string(err))

func initialize_data():
	data.energy_g = 100
	data.plants_map = {}
	data.plants = []
	data.run_time = 0

func reset():
	delete_save()
	initialize_data()
	World.initialize_plant_data()

func delete_save():
	initialize_data()
	if FileAccess.file_exists(GAME_SAVE_PATH):
		var dir = DirAccess.open("user://")
		if dir:
			dir.remove("save_data.tres")
