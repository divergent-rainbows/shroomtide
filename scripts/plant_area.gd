extends Area2D

@export var plant_data: PlantData

@onready var shroomie: CharacterBody2D 	= $"../../Shroomie"
@onready var tile_menu: Control        	= $"../../Shroomie/TileMenu" 
@onready var tile_menu_top: TextureButton = $"../../Shroomie/TileMenu/Top"

@onready var tile_states := {
	Global.HealthStatus.Unknown: $PlantTile/Dead,
	Global.HealthStatus.Dead: $PlantTile/Dead,
	Global.HealthStatus.Healing: $PlantTile/Healing,
	Global.HealthStatus.Recovered: $PlantTile/Recovered,
}

var current_plant_state
var player_in_range = false
var is_selected = false

func _ready():
	await get_tree().process_frame
	InputManager.accept.connect(_on_accept_pressed)
	current_plant_state = plant_data.get_health_status()
	update_growth_stage()

func _process(_delta):
	if plant_data.get_health_status() != current_plant_state:
		update_growth_stage()

func _on_accept_pressed():
	if player_in_range and not is_selected:
		is_selected = true
		Global.control_override = true
		Global.load_plant_data(plant_data.id)
		tile_menu.global_position = $"../../Shroomie".global_position
		tile_menu.show()
		await get_tree().create_timer(0.3).timeout
		tile_menu_top.grab_focus()

func update_growth_stage():
	for tile in tile_states.values():
		tile.hide()
	tile_states[plant_data.get_health_status()].show()
	current_plant_state = plant_data.get_health_status()

func _on_body_entered(_body: Node2D) -> void:
	player_in_range = true

func _on_body_exited(_body: Node2D) -> void:
	player_in_range = false
	is_selected = false
