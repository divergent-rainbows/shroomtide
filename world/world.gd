extends Node2D
class_name World

@onready var save_data := Save.data as SaveData
@onready var world_hud: Control = $"HUD/World HUD"
@onready var shroomie: CharacterBody2D = %Shroomie
@onready var map: TileMapLayer = $Map
var game_over: bool = false

const WORLD_PLANT_LOCATIONS = {
	Global.PlantType.Shrub: [
		Vector2i(17,32),
		Vector2i(17,28),
		Vector2i(20,26),
		Vector2i(20,34),
		Vector2i(23,28),
		Vector2i(23,32),
	],	
	Global.PlantType.Stalk:  [
		Vector2i(18,29),
		Vector2i(18,31),
		Vector2i(21,29),
		Vector2i(21,31),
	],
	Global.PlantType.Trees: [
		Vector2i(20,30)
	],
	Global.PlantType.Grass: [
		Vector2i(15,30),
		Vector2i(15,31),
		Vector2i(16,28),
		Vector2i(16,27),
		Vector2i(17,25),
		Vector2i(18,25),
		Vector2i(19,35),
		Vector2i(20,35),
		Vector2i(21,25),
		Vector2i(22,25),
		Vector2i(23,27),
		Vector2i(24,28),
		Vector2i(24,31),
		Vector2i(25,30),
		Vector2i(17,34),
		Vector2i(17,35),
		Vector2i(22,35),
		Vector2i(23,34)
	]
}

func _ready() -> void:
	var plant_coords = Global.save_data.plants_map
	for coord in plant_coords:
		instantiate_and_place_plant_on_tile(plant_coords[coord], coord)
	Global.sprint_timer.start()

static func initialize_plant_data() -> void:
	var new_plants := {} as Dictionary[Vector2i, PlantData]
	for plant_type in Global.PlantType.values():
		var starting_tiles = WORLD_PLANT_LOCATIONS[plant_type]
		for i in range(starting_tiles.size()):
			var pd = PlantData.create_from_type(plant_type)
			new_plants[starting_tiles[i]] = pd
	Save.data.upload_plants(new_plants)
	Save.data.serialize_plant_data()

func instantiate_and_place_plant_on_tile(plant: PlantData, tile_coords: Vector2i):
	var tile_control =  %TileMenu
	var new_plant_area := plant.tile.instantiate()
	new_plant_area.add_child(plant.visual_scene.instantiate())
	new_plant_area.plant_data = plant
	new_plant_area.tile_menu = tile_control
	new_plant_area.player_entered.connect(tile_control.on_player_entered_tile)
	new_plant_area.player_exited.connect(tile_control.on_player_exited_tile)
	new_plant_area.player_entered.connect(shroomie.on_player_entered_tile)
	new_plant_area.player_exited.connect(shroomie.on_player_exited_tile)
	map.add_child(new_plant_area)
	new_plant_area.position = map.map_to_local(tile_coords)

func _on_sprint_timer_timeout() -> void:
	save_data.run_time += Global.sprint_timer.wait_time

func _on_back_to_start_screen_pressed() -> void:
	Global.goto_scene(Global.START_SCREEN_PATH)

func _on_reset_data_pressed() -> void:
	Save.reset()
	Global.goto_scene(Global.START_SCREEN_PATH)
