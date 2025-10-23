extends Area2D
class_name PlantArea

signal tile_hovered(tile: Area2D)

@export var plant_data: PlantData
@onready var plant_tile_root: Node = $PlantTile

var tile_states
var current_plant_state
var player_in_range = false
var is_selected = false

func _ready():
	await get_tree().process_frame
	current_plant_state = plant_data.get_health_status()
	plant_data.on_tile_ready(self, plant_tile_root)
	plant_data.update_visuals()

func _on_area_shape_entered(_area_rid: RID, area: Area2D, area_shape_index: int, _local_shape_index: int) -> void:
	var owner_id    := area.shape_find_owner(area_shape_index)
	var shape_node  := area.shape_owner_get_owner(owner_id)
	if shape_node.is_in_group("selector"):
		tile_hovered.emit(self)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event.is_pressed() and event.is_action_type():
		tile_hovered.emit(self)
