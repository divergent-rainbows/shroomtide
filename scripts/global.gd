extends Node

const WORLD_SCENE_PATH = "res://world/world.tscn"
const START_SCREEN_PATH = "res://world/start_screen.tscn"
const PLATFORMER_SCENE_PATH = "res://platformer/platformer.tscn"

enum PlantType {Stalk, Shrub, Trees}
enum HealthStatus {Dead, Healing, Recovered}
enum LeafPosition {Left, Right}
const STARTING_TILES = [
	Vector2i(10,13),
	Vector2i(5,8),
	Vector2i(13,9),
	Vector2i(15,7),
	Vector2i(9,3),
	Vector2i(10,6),
	Vector2i(10,8),
	Vector2i(14,14),
]
const STARTING_TILES_SHRUB = [
	Vector2i(9,11),
	Vector2i(14, 11),
	Vector2i(13,5),
	Vector2i(7,7),
	Vector2i(8,4),
	Vector2i(10,6),
]
const STARTING_TILES_TREE = [
	Vector2i(12,8),
	Vector2i(8,10),
	Vector2i(7,3)
]
const GAME_SAVE_PATH = "user://save_data.tres"
const SCREEN_SCALE = 2.0
const LEFT_LANE_X = 226.0
const RIGHT_LANE_X = 435.0
var current_scene = null
var current_coords = Vector2(326.0, 285.0)
signal energy_gained(e: float, f: float, d: float, c: float)

@onready var save_data := load(GAME_SAVE_PATH) as SaveData 
var current_plant_data = null
var control_override = false

func _ready() -> void:
	randomize()
	_resize_and_relocate_window()
	var root = get_tree().root
	current_scene = root.get_child(-1)
	
	# Create Save State
	if save_data == null:
		save_data = SaveData.new()
		save_data.energy = 50
		ResourceSaver.save(save_data, GAME_SAVE_PATH)
		print("Created new save data")
	if save_data.plants.is_empty():
		var new_plants := {} as Dictionary[Vector2i, PlantData]

		for i in range(STARTING_TILES.size()):
			var pd = PlantData.new()
			new_plants[STARTING_TILES[i]] = pd
		# Set two random plants to produce alkaline:
		var p1= new_plants.values().pick_random()
		p1.a_rate = 0.1
		var p2= new_plants.values().pick_random()
		p2.a_rate = 0.1

		for i in range(STARTING_TILES_SHRUB.size()):
			var pd = PlantData.new()
			if i % 2 == 0:
				pd.set_shrub_a_defaults()
			else:
				pd.set_shrub_b_defaults()
			new_plants[STARTING_TILES_SHRUB[i]] = pd
		
		for i in range(STARTING_TILES_TREE.size()):
			var pd = PlantData.new()
			pd.set_tree_defaults()
			new_plants[STARTING_TILES_TREE[i]] = pd
		save_data.upload_plants(new_plants)
			

	# Initialize ticker
	var timer := Timer.new()
	timer.wait_time = 0.55
	timer.one_shot = false
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(_on_tick)
	

func _on_tick() -> void:
	var new_energy = 0
	var a = 0
	var p = 0
	var t = 0
	for plant in  Global.save_data.plants: 
		if plant.is_revived:
			new_energy += plant.get_leaf_count() * plant.photosynthesis_rate
			a += plant.get_alkaline_per_tick()
			p += plant.get_poly_per_tick()
			t += plant.get_terpine_per_tick()


	Global.add_energy(new_energy, a, p, t)
	Global.save_game()	
	
func save_game():
	var err = ResourceSaver.save(save_data, GAME_SAVE_PATH)
	if err != OK:
		push_error("Save failed: %s" % error_string(err))

func add_energy(amount, amount_a = 0, amount_p = 0, amount_t = 0):
	emit_signal("energy_gained", 
		amount * 0.68,
		amount_a,
		amount_p,
		amount_t)
		
	save_data.energy += amount
	save_data.energy_a += amount_a
	save_data.energy_p += amount_p
	save_data.energy_t += amount_t

func subtract_energy(amount, amount_a = 0, amount_p = 0, amount_t = 0):
	save_data.energy -= amount
	save_data.energy_a -= amount_a
	save_data.energy_p -= amount_p
	save_data.energy_t -= amount_t

# Convert pixels to "meters" (320px = 1m in game)
func convert_pixel_height_to_meters(y):
	return abs(y) / 320.0
	
func goto_scene(path):
	_deferred_goto_scene.call_deferred(path)

func load_plant_data(plant_id):
	current_plant_data = save_data.plants[plant_id]
	print(current_plant_data)
	
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
		save_data.energy = 100
		save_data.energy_a = 0
		save_data.energy_p = 0
		save_data.energy_t = 0
		save_data.plants_map = {}
		save_data.plants = []
		save_game()
	if event.is_action_pressed("esc"):
		goto_scene(START_SCREEN_PATH)
	if event.is_action_pressed("back"):
		goto_scene(WORLD_SCENE_PATH)
