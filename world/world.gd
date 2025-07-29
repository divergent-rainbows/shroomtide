extends Node2D

@export var save_data: SaveData
@onready var world_hud: Control = $"World HUD"
@onready var timer: Timer = $Timer
@onready var shroomie: CharacterBody2D = $Shroomie
@onready var map: TileMapLayer = $Map
const Plant := preload("res://world/plant_area.tscn")
const Shrub := preload("res://plant_types/plant_area_medium.tscn")
const Trees := preload("res://plant_types/plant_area_large.tscn")

func _ready() -> void:
	# persist local position between scene changes
	shroomie.position = Global.current_coords
	var plant_coords = Global.save_data.plants_map
	for coord in plant_coords:
		place_plant_on_tile(plant_coords[coord], coord)

func _process(_delta: float) -> void:
	world_hud.update()

func place_plant_on_tile(plant: PlantData, tile_coords: Vector2i):
	var new_plant := Plant.instantiate()
	if plant.type == Global.PlantType.Shrub:
		new_plant = Shrub.instantiate()
	elif plant.type == Global.PlantType.Trees:
		new_plant = Trees.instantiate()
	new_plant.plant_data = plant
	map.add_child(new_plant)
	new_plant.position = map.map_to_local(tile_coords)
	print("placed ID: %d on: %s" % [plant.id, tile_coords])
	
