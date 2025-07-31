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
