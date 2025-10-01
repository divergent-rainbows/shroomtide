extends Node

signal tick
signal game_complete

@onready var save_data := Save.data as SaveData

const WORLD_SCENE_PATH = "res://world/world.tscn"
const START_SCREEN_PATH = "res://world/start_screen.tscn"
const PLATFORMER_SCENE_PATH = "res://platformer/platformer.tscn"
const G_SYMBOL = "[img]res://assets/svg/sun.svg[/img]"

enum PlantType {Stalk, Shrub, Trees, Grass}
enum HealthStatus {Unknown, Dead, Healing, Recovered}
enum LeafPosition {Left, Right}

const LEFT_LANE_X := 226.0
const RIGHT_LANE_X := 435.0
const CAMERA_ZOOM := 3.5
var current_scene = null
var current_coords := Vector2i(20, 32)
var control_anchor := Vector2(0, 0)

var control_override = false
var sprint_timer: Timer

func _ready() -> void:
	randomize()
	_resize_and_relocate_window()
	var root = get_tree().root
	current_scene = root.get_child(-1)
	_setup_sprint_timer()
	game_complete.connect(_stop_sprint_timer)
	
func _resize_and_relocate_window():
	var target_size = Vector2i(720, 1280)
	var target_pos = DisplayServer.screen_get_size() / 2 - target_size / 2
	DisplayServer.window_set_size(target_size)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_position(target_pos)
	
func _deferred_goto_scene(path, plant_data: PlantData):
	current_scene.free()	
	var s = ResourceLoader.load(path)
	current_scene = s.instantiate()
	current_scene.set("plant_data", plant_data)
	get_tree().root.add_child(current_scene)
	get_tree().current_scene = current_scene

func _setup_sprint_timer() -> void:
	sprint_timer = Timer.new()
	sprint_timer.wait_time = 1.0
	sprint_timer.timeout.connect(_on_sprint_timer_timeout)
	add_child(sprint_timer)

func _on_sprint_timer_timeout() -> void:
	save_data.run_time += sprint_timer.wait_time
	emit_signal("tick")
	if _check_game_complete_by_plant_health():
		emit_signal("game_complete")

func _stop_sprint_timer() -> void:
	sprint_timer.stop()

func _check_game_complete_by_plant_health() -> bool: 
	var recovered_statuses = save_data.plants.map(
		func(p: PlantData): 
				return p.get_health_status() == Global.HealthStatus.Recovered
	)
	return false not in recovered_statuses

# Convert pixels to "meters" (320px = 1m in game)
func convert_pixel_height_to_meters(y):
	return abs(y) / 320.0

func goto_scene(path, plant_data = null):
	_deferred_goto_scene.call_deferred(path, plant_data)
