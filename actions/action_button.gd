extends RepeatButton
class_name ActionButton

signal action_pressed(action: PlantAction)
@onready var action_label: RichTextLabel = %ActionLabel
@onready var cost_label: RichTextLabel = %CostLabel

@export var _action: PlantAction
var _plant: PlantData
var _auto_repeat_enabled: bool = true

func _ready() -> void:
	super._ready()  # Call RepeatButton's _ready first

	if _action:
		action_label.text = _action.label
		cost_label.text = _action.get_cost(_plant).to_button_display()

	# Connect to our own pressed signal to handle action execution
	button_down.connect(_on_action_pressed)
	Eco.resources_changed.connect(func(): setup(_action, _plant))


func setup(action: PlantAction, plant: PlantData) -> void:
	_action = action
	_plant = plant
	disabled = not action.can_execute(plant) 

	# Update labels with icon in BBCode if they exist
	if action_label:
		action_label.text = action.label

	if cost_label:
		cost_label.text = action.get_cost(plant).to_button_display()
	_configure_auto_repeat()

func _configure_auto_repeat() -> void:
	if _auto_repeat_enabled:
		# Configure auto-repeat timing for plant actions
		initial_delay = 0.5
		repeat_interval = 0.15
		accelerate = true
		min_interval = 0.08
		repeat_outside = true
	else:
		# Disable auto-repeat by setting very long delays
		initial_delay = 999.0
		repeat_interval = 999.0
		accelerate = false

func _on_action_pressed() -> void:
	# Validate action can still be executed (important for auto-repeat)
	if _action and _plant and _action.can_execute(_plant):
		emit_signal("action_pressed", _action)
	else:
		# Stop auto-repeat if action can't be executed
		_holding = false
