extends Control
class_name PlantActionMenu

signal action_executed

@export var all_actions: Array[PlantAction]
@export var action_button_scene: PackedScene

var _plant
var _is_rebuilding = false

func _rebuild(plant: PlantData) -> void:
	_is_rebuilding = true
	for c in get_children():
		c.queue_free()

	if plant == null:
		return
	else:
		_plant = plant

	var visible_actions := all_actions.filter(func(a): return a.is_visible(plant))
	visible_actions.sort_custom(func(a, b): return a.priority > b.priority)
	for action in visible_actions:
		var btn: ActionButton = action_button_scene.instantiate()
		btn.setup(action, plant)
		btn.action_pressed.connect(_on_action_button_pressed)
		add_child(btn)

	await get_tree().create_timer(0.1).timeout
	_is_rebuilding = false

func _refresh_buttons(plant: PlantData):
	var existing_buttons = get_children().filter(func(c): return c is ActionButton)
	for btn in existing_buttons:
		if btn._action:
			btn.setup(btn._action, plant)  # Refresh with new plant state

func _on_action_button_pressed(action: PlantAction) -> void:
	if not _is_rebuilding: 
		action.execute(_plant)
		action_executed.emit()
