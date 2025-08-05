extends Node2D
class_name World

@onready var save_data := Save.data as SaveData
@onready var world_hud: Control = $"World HUD"
@onready var shroomie: CharacterBody2D = $Shroomie
@onready var map: TileMapLayer = $Map
@onready var sprint_timer: Timer = $SprintTimer
var game_over: bool = false

const TILE := preload("res://world/plant_area.tscn")
const STALKS = preload("res://plant_types/stalks.tscn")
const SHRUBS = preload("res://plant_types/shrubs.tscn")
const TREES = preload("res://plant_types/trees.tscn")
const WORLD_PLANT_LOCATIONS = {
	Global.PlantType.Stalk: [
		Vector2i(5,8),
		Vector2i(9,5),
		Vector2i(8,14),
		Vector2i(12,3),
		Vector2i(12,14),
		Vector2i(15,7),
		Vector2i(15,11),
	],	
	Global.PlantType.Shrub:  [
		Vector2i(7,6),
		Vector2i(10,2),
		Vector2i(10,13),
		Vector2i(11,5),
		Vector2i(13,9),
	],
	Global.PlantType.Trees: [
		Vector2i(7,10),
		Vector2i(8,4),
		Vector2i(11,8),
		Vector2i(13,5),
		Vector2i(14, 11),
	]
}

func _ready() -> void:
	# persist local position between scene changes
	var target_pos = map.map_to_local( Global.current_coords)
	shroomie.position = target_pos
	var plant_coords = Global.save_data.plants_map
	for coord in plant_coords:
		place_plant_on_tile(plant_coords[coord], coord)

func _process(_delta: float) -> void:
	if game_over:
		world_hud.show_end_of_game()
		return
	world_hud.update()
	check_game_over_by_plant_health()

static func initialize_plant_data() -> void:
	var new_plants := {} as Dictionary[Vector2i, PlantData]
	for plant_type in Global.PlantType.values():
		var starting_tiles = WORLD_PLANT_LOCATIONS[plant_type]
		for i in range(starting_tiles.size()):
			var pd = PlantData.create(plant_type)
			new_plants[starting_tiles[i]] = pd
	Save.data.upload_plants(new_plants)
	Save.data.serialize_plant_data()

func place_plant_on_tile(plant: PlantData, tile_coords: Vector2i):
	var new_plant_area := TILE.instantiate()
	new_plant_area.add_child(plant.visual_scene.instantiate())
	new_plant_area.plant_data = plant
	map.add_child(new_plant_area)
	new_plant_area.position = map.map_to_local(tile_coords)	

func _on_sprint_timer_timeout() -> void:
	save_data.run_time += sprint_timer.wait_time
	
func check_game_over_by_energy() -> void:
	var g_achieved = save_data.energy_g > Global.G_MAX
	var a_achieved = save_data.energy_a > Global.A_MAX
	var p_achieved = save_data.energy_p > Global.P_MAX
	var t_achieved = save_data.energy_t > Global.T_MAX
	if g_achieved and a_achieved and p_achieved and t_achieved:
		sprint_timer.stop()
		game_over = true

func check_game_over_by_plant_health() -> void: 
	var all_recovered = true 
	for plant in  Global.save_data.plants: 
		if plant.get_health_status() != Global.HealthStatus.Recovered:
			all_recovered = false
	if all_recovered:
		sprint_timer.stop()
		game_over = true
