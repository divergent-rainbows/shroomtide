extends Node

const GAME_SAVE_PATH = "user://save_data.tres"
@onready var data := load(GAME_SAVE_PATH) as SaveData 

func _ready() -> void: 
	if data == null:
		data = SaveData.new()
		data.energy = 50
		ResourceSaver.save(data, GAME_SAVE_PATH)
		print("Created new save data")
	if data.plants.is_empty():
		World.initialize_plant_data()

func save_game():
	var err = ResourceSaver.save(data, GAME_SAVE_PATH)
	if err != OK:
		push_error("Save failed: %s" % error_string(err))

func reset():
	print("Resetting...")
	data.energy_g = 100
	data.energy_a = 0
	data.energy_p = 0
	data.energy_t = 0
	data.plants_map = {}
	data.plants = []
	data.run_time = 0
	save_game()
