extends Node2D
class_name World

@onready var level_data: LevelSaveData
@onready var world_hud: Control = $"HUD/World HUD"
@onready var shroomie: CharacterBody2D = %Shroomie
@onready var map: TileMapLayer = $Map
@onready var network: MyceliumNetwork = %Network
@onready var inspector_view: InspectorView = $HUD/InspectorView

var game_over: bool = false

func _ready() -> void:
	var level_data = Save.get_current_level_data()
	var plant_coords = level_data.plants_map
	for coord in plant_coords:
		instantiate_and_place_plant_on_tile(plant_coords[coord], coord)
	Global.sprint_timer.start()

func instantiate_and_place_plant_on_tile(plant: PlantData, tile_coords: Vector2i):
	var new_plant_area : PlantArea = plant.tile.instantiate()
	new_plant_area.name = plant.get_plant_id_str()
	new_plant_area.add_child(plant.visual_scene.instantiate())
	new_plant_area.plant_data = plant
	new_plant_area.tile_hovered.connect(inspector_view.on_tile_hovered)
	map.add_child(new_plant_area)
	new_plant_area.position = map.map_to_local(tile_coords)
	plant._plant_area = new_plant_area
	plant._network = network


func _on_back_to_start_screen_pressed() -> void:
	Global.goto_scene(Global.START_SCREEN_PATH)


func _on_reset_data_pressed() -> void:
	Save.reset()
	Global.goto_scene(Global.START_SCREEN_PATH)
