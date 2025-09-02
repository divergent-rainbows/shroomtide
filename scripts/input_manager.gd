extends Node

# Game Mode Signals - emitted based on context
signal move_left
signal move_right  
signal move_up
signal move_down
signal accept
signal accept_released
signal jump
signal jump_released(release_position: Vector2)
signal cancel
signal back
signal reset
signal tap_at_position

# Input Device Types
enum InputDevice {
	KEYBOARD_MOUSE,
	TOUCH
}

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
	"ui_accept": [accept, jump],
	"ui_cancel": cancel
}

var current_device: InputDevice = InputDevice.KEYBOARD_MOUSE
var current_game_mode: GameMode = GameMode.WORLD
var touch_start_pos: Vector2
var touch_threshold: float = 50.0

func _ready() -> void:
	detect_device()
	_connect_input_signals()

func _input(event: InputEvent) -> void:
	match current_device:
		InputDevice.KEYBOARD_MOUSE:
			handle_keyboard_mouse_input(event)
		InputDevice.TOUCH:
			handle_touch_input(event)
	
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

func detect_device() -> void:
	if OS.has_feature("mobile"):
		current_device = InputDevice.TOUCH
	else:
		current_device = InputDevice.KEYBOARD_MOUSE

# Game Mode Management
func set_game_mode(mode: GameMode):
	current_game_mode = mode

func set_platformer_mode(enabled: bool):
	current_game_mode = GameMode.PLATFORMER if enabled else GameMode.WORLD

func is_platformer_mode() -> bool:
	return current_game_mode == GameMode.PLATFORMER

func is_world_mode() -> bool:
	return current_game_mode == GameMode.WORLD

func is_mobile_device() -> bool:
	return current_device == InputDevice.TOUCH

func is_desktop_device() -> bool:
	return current_device == InputDevice.KEYBOARD_MOUSE

func handle_keyboard_mouse_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		handle_mouse_button_input(event)
		return
	
	if event is InputEventKey:
		handle_keyboard_key_input(event)
		return

func handle_mouse_button_input(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			handle_screen_interaction(event.position)
		else:
			jump_released.emit(event.position)

func handle_keyboard_key_input(_event: InputEventKey) -> void:
	# Handle action presses and releases
	for action in keyboard_action_map:
		if Input.is_action_just_pressed(action):
			var signals = keyboard_action_map[action]
			if signals is Array:
				for signal_to_emit in signals:
					signal_to_emit.emit()
			else:
				signals.emit()
		elif Input.is_action_just_released(action):
			if action == "ui_accept":
				accept_released.emit()
				jump_released.emit(Vector2.ZERO)

func handle_touch_input(event: InputEvent) -> void:
	# filter out mouse clicksq
	if event is InputEventScreenTouch:
		handle_screen_touch_input(event)

func handle_screen_touch_input(event: InputEventScreenTouch) -> void:
	if event.pressed:
		touch_start_pos = event.position
		handle_screen_interaction(event.position)
	else:
		var swipe_vector = event.position - touch_start_pos
		if swipe_vector.length() > touch_threshold:
			handle_touch_swipe_gesture(swipe_vector)
		else:
			jump_released.emit(event.position)

func handle_screen_interaction(position: Vector2) -> void:
	match current_game_mode:
		GameMode.PLATFORMER:
			handle_platformer_screen_input(position)
		GameMode.WORLD:
			handle_world_screen_input(position)

func handle_platformer_screen_input(position: Vector2) -> void:
	var screen_width = get_viewport().get_visible_rect().size.x
	if position.x < screen_width / 2:
		move_left.emit()
		jump.emit()
	else:
		move_right.emit()
		jump.emit()
	
	accept.emit()

func handle_world_screen_input(position: Vector2) -> void:
	print("WORLD input emitting at: ", position)
	tap_at_position.emit(position)

func handle_touch_swipe_gesture(swipe_vector: Vector2) -> void:
	var normalized = swipe_vector.normalized()
	if abs(normalized.x) > abs(normalized.y):
		if normalized.x > 0:
			move_right.emit()
		else:
			move_left.emit()
	else:
		if normalized.y > 0:
			move_down.emit()
		else:
			move_up.emit()

func is_action_pressed(action: String) -> bool:
	return Input.is_action_pressed(action)

func is_action_just_pressed(action: String) -> bool:
	return Input.is_action_just_pressed(action)

func is_action_just_released(action: String) -> bool:
	return Input.is_action_just_released(action)
