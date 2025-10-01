extends Actions
class_name Tile_Menu

# Action menu layout
enum BtnPos {TOP, BTM, LEFT, RIGHT}

# UI Nodes 
enum {ACTION_LABEL, COST_LABEL}
 
# Button references for screen input
@onready var button_nodes = {
	BtnPos.TOP: $Top,
	BtnPos.LEFT: $Left, 
	BtnPos.RIGHT: $Right,
	BtnPos.BTM: $Bottom
}

@onready var UI_NODES = {
	BtnPos.TOP: {
		ACTION_LABEL: $Top/Action,
		COST_LABEL: $Top/Cost
	},
	BtnPos.LEFT: {
		ACTION_LABEL: $Left/Labels/Action,
		COST_LABEL: $Left/Labels/Cost,
	},	
	BtnPos.RIGHT: {
		ACTION_LABEL: $Right/Labels/Action,
		COST_LABEL: $Right/Labels/Cost,
	},
	BtnPos.BTM: {
		ACTION_LABEL: $Bottom/Action,
		COST_LABEL: $Bottom/Cost,
	}
}

@onready var ACTION_CONFIG = {
	Global.HealthStatus.Unknown: {
		BtnPos.TOP: ACTION_CONNECT,	
	},
	Global.HealthStatus.Dead: {
		BtnPos.TOP: ACTION_INSPECT,
		BtnPos.LEFT: ACTION_REVIVE
	},
	Global.HealthStatus.Healing: {
		BtnPos.TOP: ACTION_INSPECT,
		BtnPos.LEFT: ACTION_NURTURE,
		BtnPos.RIGHT: ACTION_GROW_LEAF
	},
	Global.HealthStatus.Recovered: {
		BtnPos.TOP: ACTION_INSPECT,
		BtnPos.LEFT: ACTION_NURTURE,
		BtnPos.RIGHT: ACTION_GROW_LEAF
	}
}

func _ready() -> void:
	# Add Back button to each menu state
	for health_state_config in ACTION_CONFIG.keys():
		ACTION_CONFIG[health_state_config][BtnPos.BTM] = ACTION_BACK
	_setup_button_layout()
	# Connect screen input for menu interaction
	Global.game_complete.connect(execute_back)
	InputManager.on_screen_touch.connect(_on_screen_tap)
	InputManager.move_left.connect(action_simulator("ui_left"))
	InputManager.move_right.connect(action_simulator("ui_right"))
	InputManager.move_up.connect(action_simulator("ui_up"))
	InputManager.move_down.connect(action_simulator("ui_down"))
	message = hud.get_node("%Message")

func _update_menu()-> void:
	if pd != null: 
		var health = pd.get_health_status()
		for btn in BtnPos.values():
			set_action(btn, health) 
			set_cost(btn)
	
func on_player_entered_tile(tile: Area2D) -> void:
	_update_menu()
	_start_dwell_timer(tile)

func on_player_exited_tile(tile: Area2D) -> void:
	if _current_tile == tile:
		_current_tile = null
		_ticket += 1  # invalidate any awaiting timer
		execute_back()

func _start_dwell_timer(tile: Area2D) -> void:
	_ticket += 1
	var my_ticket := _ticket
	
	# wait and check if ticket changed before showing menu
	await get_tree().create_timer(SHOW_DELAY_DWELL_TIME).timeout
	if my_ticket == _ticket:
		_lock_in_show_menu(tile)

func _lock_in_show_menu(tile):
	_current_tile = tile
	pd = _current_tile.plant_data if _current_tile != null else null
	_update_menu()
	_animate_buttons_from_center() 
	await _pan_camera_to_tile()
	button_nodes[BtnPos.TOP].grab_focus()
	show()

func _unlock_hide_menu():
	_current_tile = null
	_animate_buttons_to_center() 
	await _pan_camera_from_tile()
	hide()

func _pan_camera_to_tile():
	var animation_duration := 0.3
	var tween = create_tween()
	tween.set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	var cam := get_viewport().get_camera_2d()
	if cam:
		var vp_h: float = get_viewport().get_visible_rect().size.y
		var local_h := vp_h / cam.zoom.y / scale.y
		#var world_shift_y: float = (vp_h * 0.5 - top_margin_px) / cam.zoom.y
		var s := local_h * 0.05
		var target_offset := Vector2(0, s)           # move focus toward top
		var target_zoom: Vector2 = Vector2.ONE * (Global.CAMERA_ZOOM * 2.0)
		tween.tween_property(cam, "global_position", _current_tile.global_position, animation_duration)
		tween.tween_property(cam, "offset", target_offset, animation_duration)
		tween.tween_property(cam, "zoom", target_zoom, animation_duration) 

func _animate_buttons_from_center():
	var scale_factor := Global.CAMERA_ZOOM * 0.85
	var button_distance := 35 * scale_factor
	var animation_duration := 0.3
	
	# Final positions
	var final_positions = {
		BtnPos.TOP: Vector2(0, -button_distance),
		BtnPos.RIGHT: Vector2(button_distance, 0),
		BtnPos.BTM: Vector2(0, button_distance),
		BtnPos.LEFT: Vector2(-button_distance, 0)
	}
	
	# Use same sizing logic as setup
	var base_button_size := Vector2(32, 28)
	var scaled_button_size := base_button_size * scale_factor
	
	# Start all buttons at center
	for btn_pos in button_nodes:
		var button = button_nodes[btn_pos]
		button.size = scaled_button_size
		button.position = -scaled_button_size * 0.5  # Center at origin
		button.modulate.a = 0.0
	
	var tween = create_tween()
	tween.set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Animate each button to its final position
	for btn_pos in button_nodes:
		var button = button_nodes[btn_pos]
		var final_pos = final_positions[btn_pos] - (scaled_button_size * 0.5)
		tween.tween_property(button, "position", final_pos, animation_duration)
		tween.tween_property(button, "modulate:a", 1.0, animation_duration)
	
	await tween.finished


func _pan_camera_from_tile():
	var animation_duration := 0.3
	var tween = create_tween()
	tween.set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	var cam := get_viewport().get_camera_2d()
	if cam:
		 # move focus toward top
		var target_zoom: Vector2 = Vector2.ONE * Global.CAMERA_ZOOM 
		tween.tween_property(cam, "global_position", shroomie.global_position, animation_duration)
		tween.tween_property(cam, "zoom", target_zoom, animation_duration) 
	await tween.finished
	hide()

func _animate_buttons_to_center():
	var scale_factor := Global.CAMERA_ZOOM * 0.85
	var animation_duration := 0.3
	
	# Final positions
	var final_positions = {
		BtnPos.TOP: Vector2.ZERO,
		BtnPos.RIGHT: Vector2.ZERO,
		BtnPos.BTM: Vector2.ZERO,
		BtnPos.LEFT: Vector2.ZERO,
	}
	
	# Use same sizing logic as setup
	var base_button_size := Vector2(32, 28)
	var scaled_button_size := base_button_size * scale_factor
	
	var tween = create_tween()
	tween.set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Animate each button to its final position
	for btn_pos in button_nodes:
		var button = button_nodes[btn_pos]
		var final_pos = final_positions[btn_pos] - (scaled_button_size * 0.5)
		tween.tween_property(button, "position", final_pos, animation_duration)
		tween.tween_property(button, "modulate:a", 0.0, animation_duration)
	
	await tween.finished



func _on_left_pressed() -> void:
	if pd != null: 
		var available_actions = ACTION_CONFIG[pd.get_health_status()]
		if BtnPos.LEFT in available_actions:
			available_actions[BtnPos.LEFT][EXECUTE].call()

func _on_right_pressed() -> void:
	if pd != null: 
		var available_actions = ACTION_CONFIG[pd.get_health_status()]
		if BtnPos.RIGHT in available_actions:
			available_actions[BtnPos.RIGHT][EXECUTE].call()

func _on_bottom_pressed() -> void:
	if pd != null: 
		var available_actions = ACTION_CONFIG[pd.get_health_status()]
		if BtnPos.BTM in available_actions:
			available_actions[BtnPos.BTM][EXECUTE].call()

func _on_top_pressed() -> void:
	if pd != null: 
		var available_actions = ACTION_CONFIG[pd.get_health_status()]
		if BtnPos.TOP in available_actions:
			available_actions[BtnPos.TOP][EXECUTE].call()

# Screen Input Handler
func _on_screen_tap(event) -> void:
	var screen_pos = event.position
	if not visible or not event.pressed:
		return
	
	if event.pressed:
		var button_pressed = false
		# Check which button was tapped using screen coordinates
		for btn_pos in button_nodes:
			var button = button_nodes[btn_pos]
			if button.visible and _is_button_tapped(button, screen_pos):
				button.grab_focus()
				_execute_button_action(btn_pos)
				button_pressed = true
				break
		if not button_pressed:
			execute_back()

func _is_button_tapped(button: Control, screen_pos: Vector2) -> bool:
	# Check if the screen position is within the button's global rect
	var button_rect = button.get_global_rect()
	return button_rect.has_point(screen_pos)

func _execute_button_action(btn_pos: BtnPos) -> void:
	var available_actions = ACTION_CONFIG[pd.get_health_status()]
	if btn_pos in available_actions:
		available_actions[btn_pos][EXECUTE].call()
	_update_menu()

func set_action(b: BtnPos, h: Global.HealthStatus) -> void:
	var menu_state = ACTION_CONFIG[h]
	# Check if action applies to this plant
	if menu_state != null and b in menu_state: 
		UI_NODES[b][ACTION_LABEL].text = menu_state[b][DISPLAY]
		UI_NODES[b][ACTION_LABEL].show()
	else: 
		UI_NODES[b][ACTION_LABEL].hide()

func set_cost(b:BtnPos) -> void:
	var menu_state = ACTION_CONFIG[pd.get_health_status()]
	# Check if action applies to this plant
	if menu_state != null and b in menu_state \
		 # Additionally, check if the action has a cost
		and COST_FN in menu_state[b]:
			UI_NODES[b][COST_LABEL].text = format_cost(menu_state[b][COST_FN].call(pd))
			UI_NODES[b][COST_LABEL].show()
	else: 
		UI_NODES[b][COST_LABEL].hide()

func action_simulator(action: String) -> Callable:
	return func():
		var ev := InputEventAction.new()
		ev.action = action
		ev.pressed = true
		Input.parse_input_event(ev) 

func _setup_button_layout():
	var scale_factor = Global.CAMERA_ZOOM * 0.85
	var button_distance = 50 * scale_factor
	
	# Set button positions centered around origin
	var button_positions = {
		BtnPos.TOP: Vector2(0, -button_distance),
		BtnPos.RIGHT: Vector2(button_distance, 0),
		BtnPos.BTM: Vector2(0, button_distance),
		BtnPos.LEFT: Vector2(-button_distance, 0)
	}
	
	# Use fixed button size to ensure consistent centering
	var base_button_size = Vector2(32, 28)  # Approximate original button size
	var scaled_button_size = base_button_size * scale_factor
	
	for btn_pos in button_nodes:
		var button = button_nodes[btn_pos]
		button.size = scaled_button_size
		# Center the button on its position by offsetting by half its size
		button.position = button_positions[btn_pos] - (scaled_button_size * 0.5)
