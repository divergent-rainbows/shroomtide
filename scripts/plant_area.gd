extends Area2D

@export var plant_data: PlantData

@onready var message: Control = $Message
@onready var tile_menu: Control = $TileMenu
@onready var tile_states := {
	Global.HealthStatus.Unknown: $PlantTile/Dead,
	Global.HealthStatus.Dead: $PlantTile/Dead,
	Global.HealthStatus.Healing: $PlantTile/Healing,
	Global.HealthStatus.Recovered: $PlantTile/Recovered,
}

var player_in_range = false
var is_selected = false

func _process(_delta):
	show_growth()
	if player_in_range and Input.is_action_just_pressed("ui_accept"):
		if is_selected:
			pass
		else:
			is_selected = true
			Global.control_override = true
			Global.load_plant_data(plant_data.id)
			tile_menu.show()
			await get_tree().create_timer(0.3).timeout
			$TileMenu/Top.grab_focus()

func show_growth():
	for tile in tile_states.values():
		tile.hide()
	tile_states[plant_data.get_health_status()].show()

func _on_body_entered(_body: Node2D) -> void:
	player_in_range = true

func _on_body_exited(_body: Node2D) -> void:
	player_in_range = false
	is_selected = false
