extends CharacterBody2D

var global_tile_offset := Vector2(0,0)
var local_pos := Vector2i(0,0)
var movement_speed := 100.0
var facing_east = true
var is_moving = false
var target_position 

var _dwell_lock_dir    := Vector2.ZERO
var _current_tile: Area2D = null   # set/clear this from your Area2D signals


@onready var world_map: TileMapLayer = $".."
@onready var camera: Camera2D = $Camera2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void: 
	# Set camera zoom from global constant
	camera.zoom = Vector2(Global.CAMERA_ZOOM, Global.CAMERA_ZOOM)
	# Use saved coordinates if available, otherwise use current position
	local_pos = Global.current_coords
	# Position player at saved coordinates with proper centering
	position = world_map.map_to_local(local_pos) 
	target_position = position
	
	InputManager.set_platformer_mode(false)
	_connect_input_signals()

func _connect_input_signals():
	InputManager.move_left.connect(_on_move_left)
	InputManager.move_right.connect(_on_move_right)
	InputManager.move_up.connect(_on_move_up)
	InputManager.move_down.connect(_on_move_down)
	InputManager.on_change_direction.connect(_on_change_direction)
	
func _physics_process(_delta: float) -> void:
	if global_position.distance_to(target_position) > 5.0:
		# Move toward current target position using physics
		var direction = (target_position - global_position).normalized()
		facing_east = direction.x > 0 or (direction.x == 0 and facing_east)
		
		if direction != _dwell_lock_dir and _dwell_lock_dir != Vector2.ZERO:
			_cancel_dwell()
		
		var should_freeze_for_dwell = _current_tile != null and direction == _dwell_lock_dir
		
		if should_freeze_for_dwell:
			is_moving = false
			velocity = Vector2.ZERO
		else: 
			velocity = direction * movement_speed
			move_and_slide()
	else:
		is_moving = false
		position = target_position  # Snap to exact tile center
		velocity = Vector2.ZERO
		Global.current_coords = world_map.local_to_map(global_position)

func _on_change_direction(new_dir: Global.CardinalDirection) -> void:
	facing_east = new_dir == Global.CardinalDirection.East

func _on_move_left():
	if is_moving || Global.control_override:
		return
	facing_east = false
	sprite.flip_h = true
	sprite.play("east")
	move_in_direction(Vector2i.LEFT)

func _on_move_right():
	if is_moving || Global.control_override:
		return
	facing_east = true
	sprite.flip_h = false
	sprite.play("east")
	move_in_direction(Vector2i.RIGHT)

func _on_move_up():
	if is_moving || Global.control_override:
		return
	sprite.flip_h = !facing_east
	sprite.play("northeast")
	local_pos = world_map.local_to_map(global_position)
	move_in_direction(Vector2i.UP + _calc_offset())

func _on_move_down():
	if is_moving || Global.control_override:
		return
	sprite.flip_h = !facing_east
	sprite.play("southeast")
	local_pos = world_map.local_to_map(global_position)
	move_in_direction(Vector2i.DOWN + _calc_offset())

func move_in_direction(dir: Vector2i):
	local_pos = world_map.local_to_map(global_position)
	var target_tile_coords = local_pos + dir
	target_position = world_map.map_to_local(target_tile_coords) + global_tile_offset
	is_moving = true

func _calc_offset():
	var curr_odd = local_pos.y % 2 == 1
	if facing_east:
		return Vector2i.RIGHT if curr_odd else Vector2i.ZERO
	else:
		return Vector2i.ZERO if curr_odd else Vector2i.LEFT
	
func on_player_entered_tile(tile: Area2D) -> void:
	_current_tile = tile
	_dwell_lock_dir =  (target_position - global_position).normalized()

func on_player_exited_tile(tile: Area2D) -> void:
	if tile == _current_tile:
		_cancel_dwell()

func _cancel_dwell() -> void:
	var current_tile = world_map.local_to_map(global_position)
	target_position = world_map.map_to_local(current_tile) + global_tile_offset
	_dwell_lock_dir = Vector2.ZERO
