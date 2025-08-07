extends CharacterBody2D

const EAST = Vector2i(1, 0)   #  (right)
const NE = Vector2i(1, -1)  # Northeast 
const NW = Vector2i(0, -1)  # Northwest
const WEST = Vector2i(-1, 0)  # West (left)
const SW = Vector2i(-1, 1)  # Southwest
const SE = Vector2i(0, 1)    # Southeast

const ZERO = Vector2i(0,0)
const NW_OFFSET = Vector2i(-1, -1)
const SE_OFFSET = Vector2i(1, 1)

var global_tile_offset := Vector2(0,0)
var local_pos := Vector2i(0,0)
var target_tile := Vector2i(-999, -999)  # Invalid position means no target
var is_moving_to_target := false
var auto_move_timer := 0.0
var auto_move_delay := 0.2  # Delay between auto-movement steps in seconds

@onready var world_map = get_node("../Map")
var facing_east = true

func _ready() -> void: 
	# Use saved coordinates if available, otherwise use current position
	local_pos = Global.current_coords
	var target_start = world_map.map_to_local(local_pos)
	
	# Calculate offset from current position to tile center
	var current_tile_pos = world_map.local_to_map(global_position)
	var current_tile_center = world_map.map_to_local(current_tile_pos)
	global_tile_offset = position - current_tile_center
	
	# Position player at saved coordinates with proper centering
	position = target_start + global_tile_offset
	Global.current_coords = local_pos
	
	InputManager.set_platformer_mode(false)
	_connect_input_signals()

func _connect_input_signals():
	InputManager.move_left.connect(_on_move_left)
	InputManager.move_right.connect(_on_move_right)
	InputManager.move_up.connect(_on_move_up)
	InputManager.move_down.connect(_on_move_down)
	InputManager.tap_at_position.connect(_on_tap_at_position)

func _on_move_left():
	if Global.control_override:
		return
	is_moving_to_target = false  # Cancel auto-movement
	facing_east = false
	move_in_direction(WEST)

func _on_move_right():
	if Global.control_override:
		return
	is_moving_to_target = false  # Cancel auto-movement
	facing_east = true
	move_in_direction(EAST)

func _on_move_up():
	if Global.control_override:
		return
	is_moving_to_target = false  # Cancel auto-movement
	local_pos = world_map.local_to_map(global_position)
	var offset_required = local_pos.y % 2 != 1
	var dir
	if facing_east:
		dir = NW if offset_required else NE
	else:
		dir = NW_OFFSET if offset_required else NW
	move_in_direction(dir)

func _on_move_down():
	if Global.control_override:
		return
	is_moving_to_target = false  # Cancel auto-movement
	local_pos = world_map.local_to_map(global_position)
	var offset_required = local_pos.y % 2 != 1
	var dir
	if facing_east:
		dir = SE_OFFSET if !offset_required else SE
	else:
		dir = SW if offset_required else SE
	move_in_direction(dir)

func move_in_direction(dir: Vector2i):
	local_pos = world_map.local_to_map(global_position)
	var target_pos = world_map.map_to_local(local_pos + dir) + global_tile_offset
	position = target_pos  # Snap directly to tile center
	Global.current_coords = world_map.local_to_map(global_position)

func _on_tap_at_position(_screen_pos: Vector2):
	if Global.control_override:
		return
	
	# Convert screen position to world position and then to tile coordinates
	var world_pos = get_global_mouse_position()
	target_tile = world_map.local_to_map(world_pos)
	is_moving_to_target = true
	auto_move_timer = 0.0  # Start moving immediately

func _physics_process(delta: float) -> void:
	# Handle continuous movement to target with timing
	if is_moving_to_target and not Global.control_override:
		auto_move_timer -= delta
		if auto_move_timer <= 0:
			move_toward_target()
			auto_move_timer = auto_move_delay  # Reset timer for next move

func move_toward_target():
	var current_tile = world_map.local_to_map(global_position)
	var diff = target_tile - current_tile
	
	# Check if we've reached the target
	if diff.length() == 0:
		is_moving_to_target = false
		# Emit accept signal to interact with whatever is at this location
		InputManager.accept.emit()
		return
	
	# Use hexagonal grid logic to determine best move
	local_pos = current_tile
	var offset_required = local_pos.y % 2 != 1
	var chosen_dir = ZERO
	
	# Determine best hex direction based on target
	if diff.x > 0:  # Target is to the right
		facing_east = true
		if diff.y < 0:  # Target is up-right
			chosen_dir = NW if offset_required else NE
		elif diff.y > 0:  # Target is down-right
			chosen_dir = SE_OFFSET if !offset_required else SE
		else:  # Target is directly right
			chosen_dir = EAST
	elif diff.x < 0:  # Target is to the left
		facing_east = false
		if diff.y < 0:  # Target is up-left
			chosen_dir = NW_OFFSET if offset_required else NW
		elif diff.y > 0:  # Target is down-left
			chosen_dir = SW if offset_required else SE
		else:  # Target is directly left
			chosen_dir = WEST
	else:  # Same x, move vertically
		if diff.y < 0:  # Target is up
			if facing_east:
				chosen_dir = NW if offset_required else NE
			else:
				chosen_dir = NW_OFFSET if offset_required else NW
		else:  # Target is down
			if facing_east:
				chosen_dir = SE_OFFSET if !offset_required else SE
			else:
				chosen_dir = SW if offset_required else SE
	
	# Move in the calculated hex direction
	if chosen_dir != ZERO:
		move_in_direction(chosen_dir)
