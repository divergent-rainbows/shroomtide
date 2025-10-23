extends CharacterBody2D
class_name Shroomie

const IDLE_DELAY 	:= 0.8
const SNAP_EPSILON 	:= 1.0
const MIN_SPEED		:= 40.0
const MAX_SPEED 		:= 70.0

var _signal_throttle := 0.2
var _on_aim_cooldown := false
var _on_move_cooldown := false

var movement_speed 	:= 80.0
var is_moving 		: bool 
var is_released 		: bool
var is_aiming 		: bool
var local_pos 		: Vector2i
var target_pos 		: Vector2
var curr_dir 		: int

@onready var world_map: TileMapLayer = $".."
@onready var camera: Camera2D = $Camera2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var selector: HexSelector = $"../HexSelector"
@onready var hex_joystick: HexJoystick = $"../../HUD/HexJoystick"

func _ready() -> void: 
	camera.zoom = Vector2(Global.CAMERA_ZOOM, Global.CAMERA_ZOOM)
	local_pos = Save.get_current_level_data().coords
	position = world_map.map_to_local(local_pos) 
	target_pos = position
	sprite.animation = "idle"
	is_released = true
	InputManager.set_platformer_mode(false)
	_connect_input_signals()


func _physics_process(_delta: float) -> void:
	local_pos = world_map.local_to_map(position)
	Save.get_current_level_data().coords = local_pos
	_snap_location_to_grid()
	if is_moving:
		_adjust_velocity()
		move_and_slide()


func _connect_input_signals():
	InputManager.aim.connect(_on_aim)
	InputManager.move.connect(_on_move)
	InputManager.on_release.connect(_on_release)


func _on_move(dir: int):
	if _on_move_cooldown: return
	_on_move_cooldown = true
	get_tree().create_timer(_signal_throttle).timeout.connect(func(): _on_move_cooldown = false)

	curr_dir = dir
	is_moving = true
	is_released = false
	is_aiming = false


func _on_aim(dir: int):
	if _on_aim_cooldown: return
	_on_aim_cooldown = true
	get_tree().create_timer(_signal_throttle).timeout.connect(func(): _on_aim_cooldown = false)

	if not is_moving:
		curr_dir = dir
		target_pos = world_map.map_to_local(local_pos + _get_curr_hex_vector())
		_update_animation()
		selector.tween_fade_to_target(target_pos)	
	is_aiming = true
	is_released = false


func _on_release():
	is_released = true
	get_tree().create_timer(IDLE_DELAY * 0.5).timeout.connect(_on_release_timeout)


func _on_release_timeout():
	if is_released:
		selector.fade_out()
		curr_dir = -1
		get_tree().create_timer(IDLE_DELAY * 0.5).timeout.connect(_on_idle_timeout)


func _on_idle_timeout():
	if is_released: 
		sprite.animation = "idle"


func _snap_location_to_grid():
	if position.distance_to(target_pos) < SNAP_EPSILON:
		position = target_pos
		if not is_released: 
			_update_animation()
		if is_released or is_aiming: 
			is_moving = false
		else: _update_target_pos()


func _adjust_velocity():
	var direction = (target_pos - position).normalized()
	if is_released or is_aiming:
		movement_speed = max(movement_speed * 0.97, MIN_SPEED)
	else:
		movement_speed = MAX_SPEED
	set_velocity(direction * movement_speed)


func _update_target_pos():
	target_pos = world_map.map_to_local(
		local_pos + _get_curr_hex_vector())
	selector.tween_fade_to_target(target_pos)


func _update_animation() -> void:
	match curr_dir:
		HexGrid.NE:
			sprite.flip_h = false
			sprite.animation = "northeast"
		HexGrid.NW:
			sprite.flip_h = true
			sprite.animation = "northeast"
		HexGrid.E:
			sprite.flip_h = false
			sprite.animation = "east"
		HexGrid.W: 
			sprite.flip_h = true
			sprite.animation = "east"
		HexGrid.SE:
			sprite.flip_h = false
			sprite.animation = "southeast"
		HexGrid.SW:
			sprite.flip_h = true
			sprite.animation = "southeast"


func _get_curr_hex_vector() -> Vector2i:
	var curr_odd = local_pos.y % 2 == 1
	match curr_dir:
		HexGrid.NE:
			return Vector2i.UP + (Vector2i.RIGHT if curr_odd else Vector2i.ZERO)
		HexGrid.E:
			return Vector2i.RIGHT
		HexGrid.SE:
			return Vector2i.DOWN + (Vector2i.RIGHT if curr_odd else Vector2i.ZERO)
		HexGrid.SW:
			return Vector2i.DOWN + (Vector2i.ZERO if curr_odd else Vector2i.LEFT)
		HexGrid.W: 
			return Vector2i.LEFT
		HexGrid.NW:
			return Vector2i.UP + (Vector2i.ZERO if curr_odd else Vector2i.LEFT)
		_:
			return Vector2i.ZERO
