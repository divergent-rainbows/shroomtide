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

@onready var level: Node2D = $".."
@onready var timer: Timer = $"../Timer"
@onready var level_hud: Control = $"../CanvasLayer/HUD"

func _ready() -> void:
	need_to_clear_input = Input.is_action_pressed("ui_accept")

func _physics_process(delta):
	if level.is_game_over() or need_to_clear_input:
		# skip first frame to clear inputs
		if Input.is_action_just_released("ui_accept"):
			need_to_clear_input = false 
		return
	handle_h_input()
	calc_charge(delta)
	execute_jump_on_release()
	calc_vertical_velocity(delta)
	move_and_slide()
	calc_h_movement(delta)

func handle_h_input():
	if not is_on_floor():
		return
	if Input.is_action_pressed("ui_left"):
		target_x = Global.LEFT_LANE_X
	elif Input.is_action_pressed("ui_right"):
		target_x = Global.RIGHT_LANE_X
	else: 
		target_x = position.x

func execute_jump_on_release():
	if Input.is_action_just_released("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY*CHARGED_JUMP_MULTIPLIER if charge_time >= CHARGE_TIME else JUMP_VELOCITY
		charge_time = 0
		horizontal_speed = calculate_horizontal_speed_for_apex()
		
func calc_vertical_velocity(delta):
	if velocity.y > 0: # Falling
		velocity.y += GRAVITY * FALL_MULTIPLIER * delta
	elif velocity.y < 0: # Rising (jumping up)
		velocity.y += GRAVITY * RISE_MULTIPLIER * delta
	else: # velocity = 0
		velocity.y += GRAVITY * delta

func calc_charge(delta):
	if Input.is_action_pressed("ui_accept"):
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
