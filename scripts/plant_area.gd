extends Area2D

signal player_entered(tile: Area2D)
signal player_exited(tile: Area2D)

@export var plant_data: PlantData

@onready var shroomie := $"../../Map/Shroomie"
@onready var tile_menu := $"../../HUD/TileMenu"
@onready var tile_menu_top: TextureButton = $"../../HUD/TileMenu/Top"
@onready var selector: AnimatedSprite2D = $Selector

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
	current_plant_state = plant_data.get_health_status()
	update_growth_stage()

func _process(_delta):
	if plant_data.get_health_status() != current_plant_state:
		update_growth_stage()

func update_growth_stage():
	for tile in tile_states.values():
		tile.hide()
	tile_states[plant_data.get_health_status()].show()
	current_plant_state = plant_data.get_health_status()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_entered.emit(self)
		selector.show()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		selector.hide()
		player_exited.emit(self)
