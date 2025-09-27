extends Area2D
class_name PlantArea

signal player_entered(tile: Area2D)
signal player_exited(tile: Area2D)

@export var plant_data: PlantData

@onready var tile_menu := $"../../HUD/TileMenu"
@onready var tile_menu_top: TextureButton = $"../../HUD/TileMenu/Top"
@onready var selector: AnimatedSprite2D = $Selector
@onready var plant_tile_root: Node = $PlantTile   # parent of visuals

var tile_states
var current_plant_state
var player_in_range = false
var is_selected = false

func _ready():
	await get_tree().process_frame
	current_plant_state = plant_data.get_health_status()
	plant_data.on_tile_ready(self, plant_tile_root)
	plant_data.update_visuals()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_entered.emit(self)
		selector.show()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		selector.hide()
		player_exited.emit(self)
