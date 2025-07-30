extends Node2D

@export var save_data: SaveData
@onready var world_hud: Control = $"World HUD"
@onready var timer: Timer = $Timer
@onready var shroomie: CharacterBody2D = $Shroomie
@onready var map: TileMapLayer = $Map
const TILE := preload("res://world/plant_area.tscn")
const STALKS = preload("res://plant_types/stalks.tscn")
const SHRUBS = preload("res://plant_types/shrubs.tscn")
const TREES = preload("res://plant_types/trees.tscn")

func _ready() -> void:
	# persist local position between scene changes
	shroomie.position = Global.current_coords
	var plant_coords = Global.save_data.plants_map
	for coord in plant_coords:
		place_plant_on_tile(plant_coords[coord], coord)

func _process(_delta: float) -> void:
	world_hud.update()

func place_plant_on_tile(plant: PlantData, tile_coords: Vector2i):
	var new_plant := TILE.instantiate()
	match plant.type:
		Global.PlantType.Stalk:
			new_plant.add_child(STALKS.instantiate())
		Global.PlantType.Shrub:
			new_plant.add_child(SHRUBS.instantiate())
		Global.PlantType.Trees:
			new_plant.add_child(TREES.instantiate())

	new_plant.plant_data = plant
	map.add_child(new_plant)
	new_plant.position = map.map_to_local(tile_coords)
	print("placed ID: %d on: %s" % [plant.id, tile_coords])
	
