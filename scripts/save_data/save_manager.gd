extends Node

const GAME_SAVE_PATH = "user://save_data.tres"
const GAME_DATA = preload("res://world/levels/game_data.tres") as GameData

var save_data: GameSaveData 

func _ready() -> void: 
	var loaded_save = load(GAME_SAVE_PATH)
	if loaded_save and loaded_save is GameSaveData:
		if GAME_DATA.version == loaded_save.game_data.version:
			save_data = loaded_save
		else: 
			print("new version available. Data will be overwritten")
			initialize_data()
	else:
		initialize_data()


func increment_run_time(t: float) -> void:
	get_current_level_data().run_time += t


func get_current_level_data() -> LevelSaveData:
	return save_data.get_current_level_data()


func save_game():
	var err = ResourceSaver.save(save_data, GAME_SAVE_PATH)
	if err != OK:
		push_error("Save failed: %s" % error_string(err))


func initialize_data() -> void:
	save_data = GameSaveData.new()
	save_data.level_save_data = []
	var levels = GAME_DATA.levels as Array[LevelData]
	for level in levels:
		var level_save = LevelSaveData.create_from_level(level)
		level_save.id = level.name + "-" + GAME_DATA.version
		level_save.energy_g = level.starting_energy
		save_data.level_save_data.append(level_save)
	ResourceSaver.save(save_data, GAME_SAVE_PATH)
	save_data.print_to_console()


func reset():
	delete_save()
	initialize_data()


func delete_save():
	if FileAccess.file_exists(GAME_SAVE_PATH):
		var dir = DirAccess.open("user://")
		if dir:
			dir.remove("save_data.tres")
