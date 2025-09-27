extends CharacterBody2D

enum {North, Northeast, East, Southeast, South, Southwest, West, Northwest}
enum {Pivot, Walk}

const IDLE_DELAY 	:= 1.0
const SNAP_EPSILON 	:= 5.0
const POLL_EPSILON 	:= 10.0
var movement_speed 	:= 90.0
var dwell_lock_dir
var is_moving
var is_released
var curr_dir
var local_pos
var target_pos

@onready var world_map: TileMapLayer = $".."
@onready var camera: Camera2D = $Camera2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var joystick: TouchScreenJoystick = $"../../HUD/Joystick"

func _ready() -> void: 
	camera.zoom = Vector2(Global.CAMERA_ZOOM, Global.CAMERA_ZOOM)
	local_pos = Global.current_coords
	position = world_map.map_to_local(local_pos) 
	target_pos = position
	InputManager.set_platformer_mode(false)
	_connect_input_signals()

func _connect_input_signals():
	InputManager.move_left.connect(_on_move_left)
	InputManager.move_right.connect(_on_move_right)
	InputManager.move_up.connect(_on_move_up)
	InputManager.move_down.connect(_on_move_down)
	InputManager.on_change_direction.connect(_set_h_direction)
	InputManager.on_zoom.connect(_on_zoom)
	InputManager.on_release.connect(_on_release)

func _physics_process(_delta: float) -> void:
	local_pos = world_map.local_to_map(position)
	Global.current_coords = local_pos

	if position.distance_to(target_pos) < 3.0:
		position = target_pos
		if is_released:
			is_moving = false
		else:
			target_pos = world_map.map_to_local(
				local_pos + get_curr_hex_vector())
		update_animation()
	var direction = (target_pos - position).normalized()
	if dwell_lock_dir == curr_dir:
		velocity = Vector2.ZERO
		target_pos = world_map.map_to_local(local_pos)
	elif is_moving:
		velocity = direction * movement_speed
		move_and_slide()
		if get_last_slide_collision() != null:
			target_pos = position

func _on_release():
	is_released = true

func _on_move_left():
	curr_dir = West
	_queue_movement()

func _on_move_right():
	curr_dir = East
	_queue_movement()
func _on_move_up():
	match curr_dir:
		Northeast, East, Southeast:
			curr_dir = Northeast
		_, Northwest, West, Southwest:
			curr_dir = Northwest
	_queue_movement()
func _on_move_down():
	match curr_dir:
		Northeast, East, Southeast:
			curr_dir = Southeast
		_, Northwest, West, Southwest:
			curr_dir = Southwest
	_queue_movement()

func _queue_movement():
	is_moving = true
	is_released = false

func update_animation() -> void:
	if is_moving:
		match curr_dir:
			Northeast:
				sprite.flip_h = false
				sprite.play("northeast")
			Northwest:
				sprite.flip_h = true
				sprite.play("northeast")
			East:
				sprite.flip_h = false
				sprite.play("east")
			West: 
				sprite.flip_h = true
				sprite.play("east")
			Southeast:
				sprite.flip_h = false
				sprite.play("southeast")
			Southwest:
				sprite.flip_h = true
				sprite.play("southeast")
	else:
		sprite.play("idle")


func get_curr_hex_vector() -> Vector2i:
	var curr_odd = local_pos.y % 2 == 1
	match curr_dir:
		Northeast:
			return Vector2i.UP + (Vector2i.RIGHT if curr_odd else Vector2i.ZERO)
		East:
			return Vector2i.RIGHT
		Southeast:
			return Vector2i.DOWN + (Vector2i.RIGHT if curr_odd else Vector2i.ZERO)
		Southwest:
			return Vector2i.DOWN + (Vector2i.ZERO if curr_odd else Vector2i.LEFT)
		West: 
			return Vector2i.LEFT
		Northwest:
			return Vector2i.UP + (Vector2i.ZERO if curr_odd else Vector2i.LEFT)
		_:
			return Vector2i.ZERO

# -1 West, 1 East
func _set_h_direction(new_dir) -> void:
	var facing_east = new_dir > 0
	match curr_dir:
		Northeast, Northwest:
			curr_dir = Northeast if facing_east else Northwest
		East, West:
			curr_dir = East if facing_east else West
		Southeast, Southwest:
			curr_dir = Southeast if facing_east else Southwest

func _calc_h_offset():
	var curr_odd = local_pos.y % 2 == 1
	match curr_dir:
		Northeast, East, Southeast:
			return Vector2i.RIGHT if curr_odd else Vector2i.ZERO
		Northwest, West, Southwest:
			return Vector2i.ZERO if curr_odd else Vector2i.LEFT
	
func on_player_entered_tile(_tile: Area2D) -> void:
	dwell_lock_dir = curr_dir

func on_player_exited_tile(_tile: Area2D) -> void:
	cancel_dwell()

func cancel_dwell() -> void: 
	dwell_lock_dir = null
	
@onready var camera_2d: Camera2D = $Camera2D
func _on_zoom(factor) -> void:
	var minZoom = 2
	var maxZoom = 8
	camera.zoom = Vector2(1,1) * clamp(camera.zoom.x * factor, minZoom, maxZoom)
