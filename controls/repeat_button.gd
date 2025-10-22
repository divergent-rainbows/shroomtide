extends TextureButton
class_name RepeatButton

@export var initial_delay: float = 0.05   # time before repeating starts
@export var repeat_interval: float = 0.08 # time between repeats
@export var accelerate: bool = true       # speed up over time
@export var min_interval: float = 0.03    # floor for acceleration
@export var repeat_outside: bool = false  # keep repeating when cursor leaves

var _holding := false
var _current_interval := 0.0

func _ready() -> void:
	button_down.connect(_on_down)
	button_up.connect(_on_up)
	mouse_exited.connect(_on_mouse_exited)


func _on_down() -> void:
	_holding = true
	_current_interval = repeat_interval
	_start_repeat_loop()
	

func _on_up() -> void:
	_holding = false


func _on_mouse_exited() -> void:
	if not repeat_outside:
		_holding = false


func _start_repeat_loop() -> void:
	# Initial delay before repeat begins
	await get_tree().create_timer(initial_delay).timeout
	while _holding and is_inside_tree() and visible and !disabled:
		emit_signal("button_down")
		if accelerate:
			_current_interval = max(min_interval, _current_interval * 0.92)
		await get_tree().create_timer(_current_interval).timeout
