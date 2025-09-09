extends Area2D

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
	if Global.current_plant_data == null \
	 or Global.current_plant_data.id != plant_data.id:
		selector.hide()

func update_growth_stage():
	for tile in tile_states.values():
		tile.hide()
	tile_states[plant_data.get_health_status()].show()
	current_plant_state = plant_data.get_health_status()

func _on_body_entered(body: Node2D) -> void:
	#start timer
	if body.is_in_group("player"):
		player_in_range = true
		Global.load_plant_data(plant_data.id)
		selector.show()
		await get_tree().create_timer(0.5).timeout 
		is_selected = true
		Global.control_override = true
		tile_menu.global_position = \
			get_global_transform_with_canvas().origin \
			- Vector2(28, 60) # global_offset
		tile_menu.show()
		tile_menu_top.grab_focus()
	
func _on_body_exited(_body: Node2D) -> void:
	player_in_range = false
	is_selected = false
