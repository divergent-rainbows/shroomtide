extends Resource
class_name GameSaveData

const GAME_DATA = preload("res://world/levels/game_data.tres") as GameData

@export var game_data: GameData
@export var current_level := 0
@export var level_save_data: Array[LevelSaveData]

func _init() -> void:
	game_data =  GAME_DATA.duplicate(true)


func get_current_level_data() -> LevelSaveData:
	assert(current_level < level_save_data.size(), "Current level exceeded game config")
	return level_save_data[current_level]


func print_to_console() -> void: 
	print("Game Data: ", game_data.version)
	print("Levels: ", "\t", game_data.levels.size())
	for level in game_data.levels:
		print(level.id, '-', level.name)
	print("Saves: ", "\t", level_save_data.size())
	for level in level_save_data:
		level.print_to_console()
