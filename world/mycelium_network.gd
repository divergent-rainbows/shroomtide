extends HexGrid
class_name MyceliumNetwork

signal fractal_segment_finished
signal connection_finished

@export var demo_mode: bool = false

@export_group("Network Properties")
@export var grow_interval 	:= 0.1
@export var base_thickness 	:= 0.5
@export var network_color 	:= Color.WHITE
@export var rainbow_mode 	:= false

@export_group("Fractal Properties")
@export var fractal_segments	:= 5
@export var golden_ratio		:= 0.618034
@export var fractal_angle 	:= 0.74159677  # Supplement of golden angle

# Pre-calculated unit fractal pattern (calculated once, reused with transforms)
var unit_fractal_pattern: Array[Vector2] = []
var fractal_length_factors: Array[float] = []

# Color palette for connection visualization
var connection_colors: Array[Color] = [
	Color.GREEN,
	Color.CYAN,
	Color.YELLOW,
	Color.MAGENTA,
	Color.ORANGE,
	Color.LIME_GREEN,
	Color.HOT_PINK,
	Color.SKY_BLUE
]
var connection_count: int = 0
var connection_paths: Array[Array] = []
var network: Array[Vector2i] = []  # Store offset odd-r coordinates of network nodes
var lines: Array[Line2D] = []  # Store all rendered line segments for cleanup
@onready var map: TileMapLayer = $".."

var demo_network: Array[Vector2i] = [
	Vector2i(17, 32), Vector2i(17, 28), Vector2i(20, 26), Vector2i(20, 34), Vector2i(23, 28), Vector2i(23, 32),
	Vector2i(15, 30), Vector2i(15, 31), Vector2i(16, 28), Vector2i(16, 27), Vector2i(17, 25), Vector2i(18, 25),
	Vector2i(19, 35), Vector2i(20, 35), Vector2i(21, 25), Vector2i(22, 25), Vector2i(23, 27), Vector2i(24, 28),
	Vector2i(24, 31), Vector2i(25, 30), Vector2i(17, 34), Vector2i(17, 35), Vector2i(22, 35), Vector2i(23, 34),
	Vector2i(18, 29), Vector2i(18, 31), Vector2i(21, 29), Vector2i(21, 31)
]
var demo_index: int = 0
var timer: Timer
var outline_complete: bool = false

func _ready():
	calculate_unit_fractal_pattern()
	connection_paths = Save.data.network_paths
	await rebuild_network_show_connections()
	if demo_mode:
		start_demo()

func start_demo():
	clear_network()
	network.append(demo_network[0])
	demo_index = 1
	outline_complete = false
	
	while not outline_complete:
		if demo_index < demo_network.size():
			var pos = map.map_to_local(demo_network[demo_index])
			await create_connection(pos)
			demo_index += 1
		else:
			outline_complete = true

func rebuild_network_show_connections():
	for path in connection_paths:
		for i in range(path.size()):
			if not network.has(path[i]):
				network.append(path[i])
		show_network_connection(path)

func create_connection(pos: Vector2) -> Signal:
	var local_pos = map.local_to_map(pos)
	var path = get_new_connection_path(local_pos)
	add_connection_to_network(path)
	Save.data.network_paths = connection_paths
	Save.save_game()
	return await show_new_network_connection(path)

func get_new_connection_path(target: Vector2i) -> Array[Vector2i]:
	if network.size() > 0:
		var nearest_index = find_nearest_node(target)
		var start_tile = network[nearest_index]
		var astar_path = find_astar_path(start_tile, target)
		return astar_path
	else:
		return [target] # Signal new network 

func add_connection_to_network(path: Array[Vector2i]):
	for i in range(path.size()):
		if not network.has(path[i]):
			network.append(path[i])
	if path.size() > 1: connection_paths.append(path)

func clear_network():
	network.clear()
	for line in lines:
		line.queue_free()
	lines.clear()

func find_nearest_node(target_coord: Vector2i) -> int:
	var min_distance = INF
	var nearest_index = 0

	for i in range(network.size()): 
		var start_axial = offset_to_axial(network[i])
		var target_axial = offset_to_axial(target_coord)
		var distance = hex_distance(start_axial, target_axial)
		if distance < min_distance:
			min_distance = distance
			nearest_index = i
	return nearest_index

# A* Pathfinding Functions using HexGrid utilities
func find_astar_path(start_tile: Vector2i, end_tile: Vector2i) -> Array[Vector2i]:
	# Convert offset odd-r coordinates to axial coordinates
	var start_axial = offset_to_axial(start_tile)
	var end_axial = offset_to_axial(end_tile)

	# Use HexGrid's hex_line function in axial space
	var axial_path = hex_line(start_axial, end_axial)
	var result: Array[Vector2i] = []

	# Convert axial path back to offset coordinates
	for axial_coord in axial_path:
		var offset_coord = axial_to_offset(axial_coord)
		result.append(offset_coord)

	return result


func calculate_unit_fractal_pattern():
	# Calculate a unit fractal pattern pointing along positive X-axis
	# This will be rotated and scaled for each use
	unit_fractal_pattern.clear()
	fractal_length_factors.clear()

	# Calculate total length factor for normalization
	var total_length_factor = 0.0
	for i in range(fractal_segments):
		var factor = pow(golden_ratio, i)
		fractal_length_factors.append(factor)
		total_length_factor += factor

	# Create unit pattern pointing right (0 degrees) with total length of 1.0
	var current_pos = Vector2.ZERO
	var current_angle = 0.0
	var angle_offset = fractal_angle * 0.3  # Reduced angle variation

	unit_fractal_pattern.append(current_pos)  # Start point

	for i in range(fractal_segments):
		var length_factor = fractal_length_factors[i] / total_length_factor
		var segment_length = length_factor  # Unit length segment

		# Alternate direction for organic pattern
		var angle_variation = angle_offset * (1 if i % 2 == 0 else -1)
		var segment_angle = current_angle + angle_variation

		# Calculate next position
		var segment_direction = Vector2(cos(segment_angle), sin(segment_angle))
		current_pos += segment_direction * segment_length
		unit_fractal_pattern.append(current_pos)

		# Gradually steer back toward target (positive X) for next segment
		var remaining_target = Vector2(1.0, 0) - current_pos
		current_angle = remaining_target.angle()


func create_fractal_pattern(start_pos: Vector2, end_pos: Vector2, color: Color) -> Array[Line2D]:
	# Use pre-calculated unit fractal pattern, transformed to fit start->end
	var fractal_lines: Array[Line2D] = []

	if unit_fractal_pattern.size() < 2:
		return fractal_lines

	# Calculate transformation parameters
	var target_vector = end_pos - start_pos
	var target_distance = target_vector.length()
	var target_angle = target_vector.angle()

	# Transform each segment of the unit pattern
	for i in range(unit_fractal_pattern.size() - 1):
		var pattern_start = unit_fractal_pattern[i]
		var pattern_end = unit_fractal_pattern[i + 1]

		# Transform pattern points: scale by target distance, rotate by target angle, translate to start
		var world_start = pattern_start.rotated(target_angle) * target_distance + start_pos
		var world_end = pattern_end.rotated(target_angle) * target_distance + start_pos

		# Create fractal line segment
		var fractal_line = Line2D.new()
		var thickness_factor = fractal_length_factors[i] if i < fractal_length_factors.size() else 1.0
		fractal_line.width = base_thickness * thickness_factor
		fractal_line.default_color = color
		fractal_line.add_point(world_start)
		fractal_line.add_point(world_end)

		fractal_lines.append(fractal_line)

	return fractal_lines

func tween_segment(start_tile: Vector2i, end_tile: Vector2i, color: Color) -> Signal:
	# Draw an animated line between two adjacent hex tiles with optional fractal pattern
	var tilemap = get_parent() as TileMapLayer

	# Convert to node-relative positions
	var start_world = tilemap.to_global(tilemap.map_to_local(start_tile))
	var end_world = tilemap.to_global(tilemap.map_to_local(end_tile))
	var start_node_pos = to_local(start_world)
	var end_node_pos = to_local(end_world)

	# Create only fractal pattern
	var fractal_lines = create_fractal_pattern(start_node_pos, end_node_pos, color)
	for fractal_line in fractal_lines:
		add_child(fractal_line)
		fractal_line.visible = false
		lines.append(fractal_line)

	# Animate each fractal segment growing sequentially
	for i in range(fractal_lines.size()):
		var fractal_line = fractal_lines[i]
		var start_pos = fractal_line.get_point_position(0)
		var end_pos = fractal_line.get_point_position(1)

		# Start with zero length
		fractal_line.set_point_position(1, start_pos)
		fractal_line.visible = true
		# Animate this segment growing
		var tween = create_tween()
		tween.tween_method(
			func(pos): fractal_line.set_point_position(1, pos),
			start_pos,
			end_pos,
			grow_interval
		)
		await tween.finished
	return fractal_segment_finished

func show_new_network_connection(path: Array[Vector2i]) -> Signal:
	var connection_color = connection_colors[demo_index % connection_colors.size()] if rainbow_mode else network_color
	for i in range(path.size() - 1):
		var current_tile = path[i]
		var next_tile = path[i + 1]

		# Use helper method to draw each segment
		await tween_segment(current_tile, next_tile, connection_color)
	return connection_finished
	
func show_network_connection(path: Array[Vector2i]):
	var connection_color = connection_colors[demo_index % connection_colors.size()] if rainbow_mode else network_color
	for i in range(path.size() - 1):
		var current_tile = path[i]
		var next_tile = path[i + 1]

		# Use helper method to draw each segment
		await tween_segment(current_tile, next_tile, connection_color)
