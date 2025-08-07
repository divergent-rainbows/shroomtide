extends CharacterBody2D

const GRAVITY = 2400
const FALL_MULTIPLIER = 2.5 # Gravity multiplier when falling
const RISE_MULTIPLIER = 1 # Gravity multiplier when rising

const JUMP_VELOCITY = -800.0
const CHARGED_JUMP_MULTIPLIER = 1.25 
const CHARGE_TIME = 0.3

var need_to_clear_input = false
var charge_time = 0.0
var horizontal_speed = 0
var target_x = Global.LEFT_LANE_X
var is_charging = false

@onready var level: Node2D = $".."
@onready var timer: Timer = $"../Timer"
@onready var level_hud: Control = $"../CanvasLayer/HUD"

func _ready() -> void:
	need_to_clear_input = InputManager.is_action_pressed("ui_accept")
	InputManager.set_platformer_mode(true)
	_connect_input_signals()

func _connect_input_signals():
	InputManager.jump.connect(_on_jump_pressed)
	InputManager.jump_released.connect(_on_jump_released)

func _on_jump_pressed():
	is_charging = true

func _on_jump_released(release_position: Vector2):
	if is_charging and is_on_floor():
		var screen_width = get_viewport().get_visible_rect().size.x
		var desired_lane_x = position.x  # Default to current position (jump straight up)
		var left_tap = (release_position.x < screen_width / 2) if release_position != Vector2.ZERO else false
		var right_tap = (release_position.x > screen_width / 2) if release_position != Vector2.ZERO else false		
		# Determine desired lane based on input
		if InputManager.is_action_pressed("ui_left") or left_tap:
			desired_lane_x = Global.LEFT_LANE_X
		elif InputManager.is_action_pressed("ui_right") or right_tap:
			desired_lane_x = Global.RIGHT_LANE_X
		elif release_position != Vector2.ZERO:
			# For mouse/touch, determine desired lane based on release position
			if release_position.x < screen_width / 2:
				desired_lane_x = Global.LEFT_LANE_X
			else:
				desired_lane_x = Global.RIGHT_LANE_X
		
		# Only move to target lane if we're not already there
		if abs(position.x - desired_lane_x) > 10:  # Small tolerance for floating point comparison
			target_x = desired_lane_x
		else:
			target_x = position.x  # Jump straight up if already in target lane
			
		velocity.y = JUMP_VELOCITY*CHARGED_JUMP_MULTIPLIER if charge_time >= CHARGE_TIME else JUMP_VELOCITY
		charge_time = 0
		horizontal_speed = calculate_horizontal_speed_for_apex()
	is_charging = false

func _physics_process(delta):
	if level.is_game_over() or need_to_clear_input:
		# skip first frame to clear inputs
		if InputManager.is_action_just_released("ui_accept"):
			need_to_clear_input = false 
		return
	handle_h_input()
	calc_charge(delta)
	calc_vertical_velocity(delta)
	move_and_slide()
	calc_h_movement(delta)

func handle_h_input():
	# Only handle horizontal input when on floor AND not in mid-air from a jump
	if not is_on_floor() or velocity.y != 0:
		return
	if InputManager.is_action_pressed("ui_left"):
		target_x = Global.LEFT_LANE_X
	elif InputManager.is_action_pressed("ui_right"):
		target_x = Global.RIGHT_LANE_X
	else: 
		target_x = position.x


func calc_vertical_velocity(delta):
	if velocity.y > 0: # Falling
		velocity.y += GRAVITY * FALL_MULTIPLIER * delta
	elif velocity.y < 0: # Rising (jumping up)
		velocity.y += GRAVITY * RISE_MULTIPLIER * delta
	else: # velocity = 0
		velocity.y += GRAVITY * delta

func calc_charge(delta):
	if is_charging:
		charge_time += delta

func calc_h_movement(delta):
	if not is_on_floor():
		position.x = move_toward(position.x, target_x, horizontal_speed * delta)
	else:
		horizontal_speed = 0
		velocity.x = 0

func calculate_horizontal_speed_for_apex():
	var time_to_apex = abs(velocity.y) / (GRAVITY * RISE_MULTIPLIER)
	var distance = target_x - position.x
	return abs(distance / time_to_apex)
