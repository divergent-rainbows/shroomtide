extends Control
class_name HexJoystick

@export var deadzone 	: float = 25.0
@export var aimzone 		: float = 70.0
@export var base_radius 	: float =  55.0
@export var knob_radius 	: float = 50.0

@export var base_texture	: Texture2D
@export var knob_texture	: Texture2D
@export var base_scale 	: Vector2 	= Vector2.ONE
@export var knob_scale 	: Vector2 	= Vector2.ONE

var hex_direction : int :
	set(value):
		# Haptic on change direction
		if value != hex_direction:
			InputManager.haptic_once()
		hex_direction = value

var tilt : float :
	set(value):
		# Haptic on movement start
		if value > aimzone and tilt < aimzone:
			InputManager.haptic_once() 
		tilt = value

var center 			: Vector2
var knob_position 	: Vector2
var is_pressing 		: bool
var event_index 		: int = -1

func _draw() -> void:
	if not is_pressing : _reset_knob()
	_draw_texture_joystick()

func _draw_texture_joystick() -> void:
	var base_size := base_texture.get_size() * base_scale
	draw_texture_rect(base_texture, Rect2(size / 2.0 - (base_size / 2.0), base_size), false)
		
	var knob_size := knob_texture.get_size() * knob_scale
	draw_texture_rect(knob_texture, Rect2(knob_position - (knob_size / 2.0), knob_size), false)

func _ready() -> void:
	center = size / 2.0
	hide()
	InputManager.on_screen_touch.connect(_on_screen_touch)
	InputManager.on_screen_drag.connect(_on_screen_drag)

func _on_screen_touch(event : InputEventScreenTouch) -> void:
	var first_finger_press_event = event.pressed and event_index == -1
	if first_finger_press_event and not Global.control_override:
		Global.control_anchor = event.position
		show()
		event_index = event.index
		is_pressing = true
	else:
		_release_knob(event.index)
		hide()
		
func _on_screen_drag(event : InputEventScreenDrag) -> void:
	if event.index == event_index and is_pressing:
		_move_knob(event.position)
	
func _get_local_delta(event_pos : Vector2) -> Vector2:
	var delta_screen := event_pos - Global.control_anchor
	return delta_screen / scale
	
func _move_knob(event_pos : Vector2) -> void:
	var delta_local := _get_local_delta(event_pos)
	var distance_to_touch := delta_local.length()
	var angle := get_radian_angle(delta_local)
	
	if distance_to_touch < base_radius:
		knob_position = center + delta_local
	else:
		knob_position.x = center.x + cos(angle) * base_radius
		knob_position.y = center.y + sin(angle) * base_radius
		
	trigger_actions(delta_local)
	queue_redraw()

func _release_knob(index : int) -> void:
	if index == event_index:
		_reset_knob()
		is_pressing = false
		event_index = -1  # Reset event index so next touch can activate joystick
		InputManager.on_release.emit()
		
func _reset_knob() -> void:
	knob_position = size / 2.0
	queue_redraw()

## -PI 	-> ZERO	 crosses Vector2.UP
## ZERO 	-> PI	 crosses Vector2.DOWN
func get_radian_angle(delta_local: Vector2) -> float:
	return center.angle_to_point(center + delta_local)

func get_hex_direction(angle: float):
	match angle:
		_ when angle >= -PI/6 and angle < PI/6:
			return HexGrid.E
		_ when angle >= PI/6 and angle < PI/2:
			return HexGrid.SE
		_ when angle >= PI/2 and angle < 5*PI/6:
			return HexGrid.SW
		_ when angle >= 5*PI/6 or angle < -5*PI/6:
			return HexGrid.W
		_ when angle >= -5*PI/6 and angle < -PI/2:
			return HexGrid.NW
		_ when angle >= -PI/2 and angle < -PI/6:
			return HexGrid.NE

func trigger_actions(delta_local: Vector2) -> void:	
	var angle = get_radian_angle(delta_local)
	tilt = delta_local.length()
	hex_direction = get_hex_direction(angle)
			
	match tilt:
		_ when tilt < deadzone:
			pass
		_ when tilt < aimzone:
			InputManager.aim.emit(hex_direction)
		_ :
			InputManager.move.emit(hex_direction)
