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

@onready var world_map = get_node("../Map")
var facing_east = true

func _ready() -> void: 
	local_pos = world_map.local_to_map(global_position)
	var target_start = world_map.map_to_local(local_pos)
	global_tile_offset = position - target_start

func _physics_process(_delta: float) -> void:
	if Global.control_override:
		return
	var local_pos = world_map.local_to_map(global_position)
	var offset_required = local_pos.y % 2 != 1 # apply offset on even rows
	var target_pos = null
	var dir = ZERO
	var speed = 100
	
	if Input.is_action_just_pressed("left"):
		facing_east = false
		dir = WEST
	elif Input.is_action_just_pressed("right"):
		facing_east = true
		dir = EAST
	elif Input.is_action_just_pressed("up"):
		if facing_east:
			dir = NW if offset_required else NE
		else:
			dir = NW_OFFSET if offset_required else NW
	elif Input.is_action_just_pressed("down"):
		if facing_east:
			dir = SE_OFFSET if !offset_required else SE
		else:
			dir = SW if offset_required else SE
	
	target_pos = world_map.map_to_local(local_pos + dir) + global_tile_offset
	position = position.move_toward(target_pos, speed)
	Global.current_coords = world_map.local_to_map(global_position)
