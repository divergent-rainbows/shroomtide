extends Node

@onready var save_data := Save.data as SaveData

const WORLD_SCENE_PATH = "res://world/world.tscn"
const START_SCREEN_PATH = "res://world/start_screen.tscn"
const PLATFORMER_SCENE_PATH = "res://platformer/platformer.tscn"

enum PlantType {Stalk, Shrub, Trees}
enum HealthStatus {Dead, Healing, Recovered}
enum LeafPosition {Left, Right}

const SCREEN_SCALE = 2.0
const LEFT_LANE_X = 226.0
const RIGHT_LANE_X = 435.0
var current_scene = null
var current_coords = Vector2i(10, 8)

var current_plant_data = null
var control_override = false

func _ready() -> void:
	randomize()
	_resize_and_relocate_window()
	var root = get_tree().root
	current_scene = root.get_child(-1)

# Convert pixels to "meters" (320px = 1m in game)
func convert_pixel_height_to_meters(y):
	return abs(y) / 320.0
	
func goto_scene(path):
	_deferred_goto_scene.call_deferred(path)

func load_plant_data(plant_id):
	current_plant_data = save_data.plants[plant_id]
	
func _resize_and_relocate_window():
	DisplayServer.window_set_size(Vector2i(1280*SCREEN_SCALE, 720*SCREEN_SCALE))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_position(Vector2i(0, 0))
	
func _deferred_goto_scene(path):
	current_scene.free()	
	var s = ResourceLoader.load(path)
	current_scene = s.instantiate()
	get_tree().root.add_child(current_scene)
	get_tree().current_scene = current_scene
	
func _input(event):
	if event.is_action_pressed("reset"):
		goto_scene(START_SCREEN_PATH)
		print("Resetting...")
		save_data.energy_g = 100
		save_data.energy_a = 0
		save_data.energy_p = 0
		save_data.energy_t = 0
		save_data.plants_map = {}
		save_data.plants = []
		Save.save_game()
	if event.is_action_pressed("esc"):
		goto_scene(START_SCREEN_PATH)
	if event.is_action_pressed("back"):
		goto_scene(WORLD_SCENE_PATH)
