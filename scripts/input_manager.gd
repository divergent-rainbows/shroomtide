extends Node

# Game Mode Signals - emitted based on context
signal move_left
signal move_right  
signal move_up
signal move_down
signal accept
signal accept_released
signal charge_jump
signal jump_released(release_position: Vector2)
signal cancel
signal back
signal reset
signal on_screen_touch
signal on_screen_drag
signal on_change_direction

# Game Mode Types
enum GameMode {
	WORLD,
	PLATFORMER
}

# Keyboard/Mouse Action Mappings
var keyboard_action_map = {
	"reset": reset,
	"esc": cancel,
	"back": back,
	"ui_left": move_left,
	"ui_right": move_right,
	"ui_up": move_up,
	"ui_down": move_down,
	"ui_accept": accept,
	"ui_cancel": cancel
}

var current_game_mode: GameMode = GameMode.WORLD
var touch_start_pos: Vector2
var touch_threshold: float = 50.0
var held_keys: Array
var simulated_touch_midpoint_multiplier = {
	"Right": 1.5,
	"Left": 0.5
}

func _ready() -> void:
	_connect_input_signals()

func in_world_mode():
	return GameMode.WORLD == current_game_mode

func in_platformer_mode():
	return GameMode.PLATFORMER == current_game_mode

func _input(event: InputEvent) -> void:
	# filter and route global input events
	match event:
		_ when event is InputEventScreenTouch and in_world_mode():
			on_screen_touch.emit(event)
		_ when event is InputEventScreenTouch and in_platformer_mode():
			_handle_platformer_screen_input(event)
		_ when event is InputEventKey and in_world_mode():
			_handle_world_key_input(event)
		_ when event is InputEventKey and in_platformer_mode():
			_handle_platformer_key_input(event)
		_ when event is InputEventScreenDrag:
			on_screen_drag.emit(event)

func _handle_platformer_screen_input(event: InputEventScreenTouch) -> void:
	charge_jump.emit() if event.pressed else jump_released.emit(event.position)
	accept.emit()

func _handle_platformer_key_input(event: InputEventKey) -> void:
	for action in keyboard_action_map:
		if event.is_action_pressed(action):
			held_keys.append(event.as_text_keycode())
			keyboard_action_map[action].emit()
			if action == "ui_accept":
				charge_jump.emit()
		elif event.is_action_released(action):
			var key = event.as_text_keycode()
			# when scenes change, held_keys is refreshed. this check 
			# prevents firing keys held during transition 
			if key in held_keys and action == "ui_accept":
				simulate_jump_release(event)
			held_keys.erase(event.as_text_keycode())

func simulate_jump_release(event: InputEventKey) -> void: 
	var screen_mid_point = get_viewport().get_visible_rect().size.x / 2
	var simulated_pos = Vector2(screen_mid_point,0)
	# platformer script handles touch input based on
	# the side of the screen touched, so we simulate 
	# touch on the relevant side of the screen 
	var held_direction_keys = held_keys.filter(
			func(d): return d in simulated_touch_midpoint_multiplier.keys())
	if held_direction_keys.size() > 0:
		var last_pressed_direction = held_direction_keys[-1] 
		var x_pos = simulated_touch_midpoint_multiplier[last_pressed_direction]
		simulated_pos.x = x_pos * screen_mid_point
	jump_released.emit(simulated_pos)

func _handle_world_key_input(event: InputEventKey) -> void:
	# Handle action presses and releases using the event directly
	for action in keyboard_action_map:
		if event.is_action_pressed(action) and event.pressed:
			var signals = keyboard_action_map[action]
			if signals is Array:
				for signal_to_emit in signals:
					signal_to_emit.emit()
			else:
				signals.emit()
		elif event.is_action_released(action):
			if action == "ui_accept":
				accept_released.emit()			
	
func _connect_input_signals():
	reset.connect(_on_reset_pressed)
	cancel.connect(_on_cancel_pressed)
	back.connect(_on_back_pressed)

func _on_reset_pressed():
	Global.goto_scene(Global.START_SCREEN_PATH)
	Save.reset()

func _on_cancel_pressed():
	Global.goto_scene(Global.START_SCREEN_PATH)

func _on_back_pressed():
	Global.goto_scene(Global.WORLD_SCENE_PATH)
	
# Game Mode Management
func set_game_mode(mode: GameMode):
	held_keys.clear()
	current_game_mode = mode

func set_platformer_mode(enabled: bool):
	held_keys.clear()
	current_game_mode = GameMode.PLATFORMER if enabled else GameMode.WORLD

func is_action_pressed(action: String) -> bool:
	return Input.is_action_pressed(action)

func is_action_just_pressed(action: String) -> bool:
	return Input.is_action_just_pressed(action)

func is_action_just_released(action: String) -> bool:
	return Input.is_action_just_released(action)
