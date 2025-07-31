extends Node2D

const START_Y = 15

const NORMAL_JUMP_HEIGHT = 6 
const CHARGED_JUMP_HEIGHT = 8

@onready var plant_data = Global.current_plant_data
@onready var leaf_tileset: TileSet = load("res://assets/level_pallette.tres")
@onready var leaf_map: TileMapLayer = $Leaves
@onready var player: CharacterBody2D = $"Level Shroomie"
@onready var hud: Control = $"CanvasLayer/Level HUD"
@onready var timer: Timer = $Timer

var platform_tile_pattern: TileMapPattern = null
var left_lane = null
var right_lane = null

var offset_y = NORMAL_JUMP_HEIGHT
const OFFSET_X = 3 # 50% of platorm width

var final_leaf_reached = false
var leaves_healed = []
var starting_y = 0
var run_height = 0

func _ready():
	print("Starting level for Plant %d" % Global.current_plant_data.id)
	starting_y = player.position.y
	left_lane = leaf_map.local_to_map(Vector2(Global.LEFT_LANE_X, 0)).x
	right_lane = leaf_map.local_to_map(Vector2(Global.RIGHT_LANE_X, 0)).x
	generate_leaves(plant_data.leaves)
	hud.update_record_height(plant_data.height_reached)

func _process(_delta: float) -> void:
	run_height = max((starting_y - player.position.y), run_height)
	hud.update(run_height)
	calc_leaves_healed()
	if is_game_over():
		var energy_gained = leaves_healed.size() * plant_data.run_multiplier
		hud.	show_run_stats(energy_gained)
		if Input.is_action_just_released("jump"):
			update_stats(energy_gained)
			Global.goto_scene(Global.WORLD_SCENE_PATH)

func is_game_over():
	var finish_line = START_Y - offset_y + NORMAL_JUMP_HEIGHT
	var player_coords = leaf_map.local_to_map(player.position)
	final_leaf_reached = (player_coords.y <= finish_line) 
	return (final_leaf_reached and player.is_on_floor()) or timer.is_stopped()
	
func calc_leaves_healed():
	var collision = player.get_last_slide_collision()
	if (collision != null) and \
		(collision.get_position().y not in leaves_healed) and \
		(collision.get_position().y != starting_y):		
		leaves_healed.append(collision.get_position().y)
		
# Create level using leaf positions
func generate_leaves(leaf_positions: Array[Global.LeafPosition]):
	if leaf_tileset is TileSet and leaf_tileset.get_patterns_count() > 0:
		platform_tile_pattern = leaf_tileset.get_pattern(0)
	else: 
		print("Could not load pattern from level_pallette.tres")
		return
		
	for leaf_pos in leaf_positions:
		match leaf_pos:
			Global.LeafPosition.Left:
				var pos = Vector2i(left_lane - OFFSET_X, START_Y - offset_y)
				leaf_map.set_pattern(pos, platform_tile_pattern)
				offset_y += NORMAL_JUMP_HEIGHT
			Global.LeafPosition.Right:
				var pos = Vector2i(right_lane - OFFSET_X, START_Y - offset_y)
				leaf_map.set_pattern(pos, platform_tile_pattern)
				offset_y += NORMAL_JUMP_HEIGHT
				
# Ran after run
func update_stats(energy_gained):
	var pd = Global.current_plant_data
	
	pd.height_reached = max( 
		Global.convert_pixel_height_to_meters(run_height), 
		pd.height_reached
	) 
	pd.leaves_reached = max(leaves_healed.size(), pd.leaves_reached)
	
	pd.total_runs += 1
