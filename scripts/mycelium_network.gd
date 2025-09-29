extends HexGrid
class_name MyceliumNetwork

@export var fractal_network_auto_grow: bool = false
@export var grow_interval: float = 1.0

@export_group("Network Appearance")
@export var network_color: Color = Color.GREEN
@export var network_thickness: float = 0.5

@export_group("Fractal Properties")
@export var enable_fractals: bool = true
@export var fractal_only: bool = false  # Only draw fractal pattern, no main line
@export var fractal_segments: int = 5
@export var golden_ratio: float = 0.618034
@export var fractal_angle: float = 0.74159677  # Supplement of golden angle

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

var network: Array[Vector2i] = []  # Store offset odd-r coordinates of network nodes
var lines: Array[Line2D] = []  # Store all rendered line segments for cleanup

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
	if fractal_network_auto_grow:
		start_network_demo()

func start_network_demo():
	clear_network()
	demo_index = 0
	outline_complete = false
	timer = Timer.new()
	timer.wait_time = grow_interval
	timer.timeout.connect(_network_demo_step)
	add_child(timer)
	timer.start()

func _network_demo_step():
	if not outline_complete:
		if demo_index < demo_network.size():
			# Store offset coordinate directly
			var offset_coord = demo_network[demo_index]
			network.append(offset_coord)

			# Connect to nearest node using A* pathfinding
			if network.size() >= 2:
				var current_pos = network[network.size() - 1]  # Current point
				var nearest_index = find_nearest_node(current_pos)

				# Find A* path between nearest node and current node
				var start_tile = network[nearest_index]
				var end_tile = network[network.size() - 1]
				var astar_path = find_astar_path(start_tile, end_tile)
				if astar_path.size() > 1:
					# Add all intermediate nodes from A* path to network (skip first node - already exists)
					for i in range(1, astar_path.size()):
						if not network.has(astar_path[i]):
							network.append(astar_path[i])

					# Draw animated lines along network connection
					await tween_network_connection(astar_path)
			demo_index += 1
		else:
			outline_complete = true
			timer.queue_free()
	else:
		timer.queue_free()


func clear_network():
	network.clear()
	connection_count = 0
	for line in lines:
		line.queue_free()
	lines.clear()

func find_nearest_node(target_coord: Vector2i) -> int:
	# Find the nearest node in the network using hex distance (excluding the target position itself)
	var min_distance = INF
	var nearest_index = 0

	for i in range(network.size() - 1):  # Exclude the last node (current position)
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

	if not enable_fractals or unit_fractal_pattern.size() < 2:
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

		# Create fractal line segment (initially hidden - will be shown during animation)
		var fractal_line = Line2D.new()
		var thickness_factor = fractal_length_factors[i] if i < fractal_length_factors.size() else 1.0
		fractal_line.width = network_thickness * (0.3 + thickness_factor * 0.7)  # Reduced diminishing factor
		fractal_line.default_color = color
		fractal_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		fractal_line.end_cap_mode = Line2D.LINE_CAP_ROUND
		fractal_line.add_point(world_start)
		fractal_line.add_point(world_end)

		fractal_lines.append(fractal_line)

	return fractal_lines

func tween_segment(start_tile: Vector2i, end_tile: Vector2i, color: Color):
	# Draw an animated line between two adjacent hex tiles with optional fractal pattern
	var tilemap = get_parent() as TileMapLayer

	# Convert to node-relative positions
	var start_world = tilemap.to_global(tilemap.map_to_local(start_tile))
	var end_world = tilemap.to_global(tilemap.map_to_local(end_tile))
	var start_node_pos = to_local(start_world)
	var end_node_pos = to_local(end_world)

	if fractal_only:
		# Create only fractal pattern
		var fractal_lines = create_fractal_pattern(start_node_pos, end_node_pos, color)
		for fractal_line in fractal_lines:
			add_child(fractal_line)
			lines.append(fractal_line)

		# Animate each fractal segment growing sequentially and wait for all to complete
		for i in range(fractal_lines.size()):
			var fractal_line = fractal_lines[i]
			var start_pos = fractal_line.get_point_position(0)
			var end_pos = fractal_line.get_point_position(1)

			# Start with zero length
			fractal_line.set_point_position(1, start_pos)

			# Calculate duration proportional to segment length using golden ratio factor
			var length_factor = fractal_length_factors[i] if i < fractal_length_factors.size() else 1.0
			var segment_duration = grow_interval * length_factor

			# Animate this segment growing and wait for completion
			var tween = create_tween()
			tween.tween_method(
				func(pos): fractal_line.set_point_position(1, pos),
				start_pos,
				end_pos,
				segment_duration
			)
			await tween.finished

		# All fractal segments are now complete
	else:
		# Create main line with specified color
		var line = Line2D.new()
		line.width = network_thickness
		line.default_color = color
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.add_point(start_node_pos)
		line.add_point(start_node_pos)  # Start with zero length
		add_child(line)
		lines.append(line)

		# Create fractal pattern if enabled
		var fractal_lines = create_fractal_pattern(start_node_pos, end_node_pos, color)
		for fractal_line in fractal_lines:
			add_child(fractal_line)
			lines.append(fractal_line)

		# Animate main segment growing and wait for completion
		var tween = create_tween()
		tween.tween_method(
			func(pos): line.set_point_position(1, pos),
			start_node_pos,
			end_node_pos,
			grow_interval
		)
		await tween.finished

func tween_network_connection(path: Array[Vector2i]):
	# Animate lines along the network connection with rotating colors

	# Get color for this connection
	var connection_color = connection_colors[connection_count % connection_colors.size()]
	connection_count += 1

	for i in range(path.size() - 1):
		var current_tile = path[i]
		var next_tile = path[i + 1]

		# Use helper method to draw each segment
		await tween_segment(current_tile, next_tile, connection_color)
