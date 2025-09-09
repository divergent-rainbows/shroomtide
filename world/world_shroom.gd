extends CharacterBody2D

var global_tile_offset := Vector2(0,0)
var local_pos := Vector2i(0,0)
var movement_speed := 100.0
var facing_east = true
var is_moving = false
var target_position 

@onready var world_map: TileMapLayer = $".."
@onready var camera: Camera2D = $Camera2D

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

func _on_change_direction(new_dir: Global.CardinalDirection) -> void:
	facing_east = new_dir == Global.CardinalDirection.East

func _on_move_left():
	if is_moving || Global.control_override:
		return
	facing_east = false
	move_in_direction(Vector2i.LEFT)

func _on_move_right():
	if is_moving || Global.control_override:
		return
	facing_east = true
	move_in_direction(Vector2i.RIGHT)

func _on_move_up():
	if is_moving || Global.control_override:
		return
	local_pos = world_map.local_to_map(global_position)
	move_in_direction(Vector2i.UP + _calc_offset())

func _on_move_down():
	if is_moving || Global.control_override:
		return
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
	
func _physics_process(_delta: float) -> void:
	if global_position.distance_to(target_position) > 5.0:
		# Move toward current target position using physics
		var direction = (target_position - global_position).normalized()
		facing_east = direction.x > 0 or facing_east
		velocity = direction * movement_speed
		move_and_slide()
		
		if get_slide_collision_count() > 0:
			var current_tile = world_map.local_to_map(global_position)
			target_position = world_map.map_to_local(current_tile) + global_tile_offset
	else:
		is_moving = false
		position = target_position  # Snap to exact tile center
		velocity = Vector2.ZERO
		Global.current_coords = world_map.local_to_map(global_position)
