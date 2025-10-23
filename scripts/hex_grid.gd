extends Node2D
class_name HexGrid

enum {E, NE, NW, W, SW, SE}

# Hex grid properties
@export var hex_size: float = 32.0
@export var hex_layout: String = "pointy"  # "pointy" or "flat"

# Hex direction vectors in axial coordinates (pointy-top)
const HEX_DIRECTIONS = [
	Vector2(1, 0),    # East
	Vector2(1, -1),   # Northeast
	Vector2(0, -1),   # Northwest
	Vector2(-1, 0),   # West
	Vector2(-1, 1),   # Southwest
	Vector2(0, 1)     # Southeast
]

# Convert world position to hex axial coordinates
func world_to_hex_coord(world_pos: Vector2) -> Vector2:
	var local_pos = to_local(world_pos)

	# Convert to axial coordinates
	var q: float
	var r: float

	if hex_layout == "pointy":
		q = (sqrt(3.0) / 3.0 * local_pos.x - 1.0 / 3.0 * local_pos.y) / hex_size
		r = (2.0 / 3.0 * local_pos.y) / hex_size
	else: # flat
		q = (2.0 / 3.0 * local_pos.x) / hex_size
		r = (-1.0 / 3.0 * local_pos.x + sqrt(3.0) / 3.0 * local_pos.y) / hex_size

	# Round to nearest hex
	return axial_round(Vector2(q, r))

# Convert hex axial coordinates to world position
func hex_coord_to_world(hex_coord: Vector2) -> Vector2:
	var q = hex_coord.x
	var r = hex_coord.y

	var local_pos: Vector2

	if hex_layout == "pointy":
		local_pos.x = hex_size * (sqrt(3.0) * q + sqrt(3.0) / 2.0 * r)
		local_pos.y = hex_size * (3.0 / 2.0 * r)
	else: # flat
		local_pos.x = hex_size * (3.0 / 2.0 * q)
		local_pos.y = hex_size * (sqrt(3.0) / 2.0 * q + sqrt(3.0) * r)

	return to_global(local_pos)

# Round fractional axial coordinates to nearest hex
func axial_round(axial: Vector2) -> Vector2:
	# Convert to cube coordinates for rounding
	var q = axial.x
	var r = axial.y
	var s = -q - r

	var rounded_q = round(q)
	var rounded_r = round(r)
	var rounded_s = round(s)

	var q_diff = abs(rounded_q - q)
	var r_diff = abs(rounded_r - r)
	var s_diff = abs(rounded_s - s)

	if q_diff > r_diff and q_diff > s_diff:
		rounded_q = -rounded_r - rounded_s
	elif r_diff > s_diff:
		rounded_r = -rounded_q - rounded_s
	else:
		rounded_s = -rounded_q - rounded_r

	# Convert back to axial
	return Vector2(rounded_q, rounded_r)

# Calculate distance between two hex coordinates
func hex_distance(hex_a: Vector2, hex_b: Vector2) -> int:
	# Convert to cube coordinates for distance calculation
	var cube_a = axial_to_cube(hex_a)
	var cube_b = axial_to_cube(hex_b)
	var diff = cube_subtract(cube_a, cube_b)
	return int((abs(diff.x) + abs(diff.y) + abs(diff.z)) / 2)

# Convert axial to cube coordinates
func axial_to_cube(axial: Vector2) -> Vector3:
	var q = axial.x
	var r = axial.y
	var s = -q - r
	return Vector3(q, r, s)

# Convert cube to axial coordinates
func cube_to_axial(cube: Vector3) -> Vector2:
	return Vector2(cube.x, cube.y)

# Subtract two cube coordinates
func cube_subtract(cube_a: Vector3, cube_b: Vector3) -> Vector3:
	return Vector3(cube_a.x - cube_b.x, cube_a.y - cube_b.y, cube_a.z - cube_b.z)

# Add two axial coordinates
func axial_add(axial_a: Vector2, axial_b: Vector2) -> Vector2:
	return Vector2(axial_a.x + axial_b.x, axial_a.y + axial_b.y)

# Get neighboring hex coordinate in given direction (0-5)
func hex_neighbor(hex_coord: Vector2, direction: int) -> Vector2:
	if direction < 0 or direction >= HEX_DIRECTIONS.size():
		push_error("Invalid hex direction: " + str(direction))
		return hex_coord

	return axial_add(hex_coord, HEX_DIRECTIONS[direction])

# Get all 6 neighboring hex coordinates
func get_hex_neighbors(hex_coord: Vector2) -> Array[Vector2]:
	var neighbors: Array[Vector2] = []
	for i in range(6):
		neighbors.append(hex_neighbor(hex_coord, i))
	return neighbors

# Find all hexes within a given range
func get_hexes_in_range(center_hex: Vector2, max_range: int) -> Array[Vector2]:
	var hexes: Array[Vector2] = []

	for q in range(-max_range, max_range + 1):
		var r1 = max(-max_range, -q - max_range)
		var r2 = min(max_range, -q + max_range)

		for r in range(r1, r2 + 1):
			var hex_coord = axial_add(center_hex, Vector2(q, r))
			hexes.append(hex_coord)

	return hexes

# Get hex coordinates along a line between two hexes
func hex_line(hex_a: Vector2, hex_b: Vector2) -> Array[Vector2]:
	var distance = hex_distance(hex_a, hex_b)
	var line: Array[Vector2] = []

	for i in range(distance + 1):
		var t = float(i) / float(distance) if distance > 0 else 0.0
		var interpolated = axial_lerp(hex_a, hex_b, t)
		line.append(axial_round(interpolated))

	return line

# Linear interpolation between two axial coordinates
func axial_lerp(hex_a: Vector2, hex_b: Vector2, t: float) -> Vector2:
	return Vector2(
		lerp(hex_a.x, hex_b.x, t),
		lerp(hex_a.y, hex_b.y, t)
	)

# Convert hex coordinate to string for use as dictionary key
func hex_to_string(hex_coord: Vector2) -> String:
	return str(int(hex_coord.x)) + "," + str(int(hex_coord.y))

# Convert string back to hex coordinate
func string_to_hex(hex_string: String) -> Vector2:
	var parts = hex_string.split(",")
	if parts.size() != 2:
		push_error("Invalid hex string format: " + hex_string)
		return Vector2.ZERO

	return Vector2(float(parts[0]), float(parts[1]))

# Convert offset odd-r coordinates to axial coordinates
func offset_to_axial(offset_coord: Vector2i) -> Vector2:
	var col = offset_coord.x
	var row = offset_coord.y
	var q = floor(col - (row - (row & 1)) / 2.0)
	var r = row
	return Vector2(q, r)

# Convert axial coordinates to offset odd-r coordinates
func axial_to_offset(axial_coord: Vector2) -> Vector2i:
	var q = axial_coord.x
	var r = axial_coord.y
	var col = q + (r - (int(r) & 1)) / 2
	var row = r
	return Vector2i(int(col), int(row))

static func get_dir_str(dir: int):
	match dir:
		E: 	return "East"
		NE: return "Northeast"
		NW: return "Northwest"
		W: 	return "West"
		SW: return "Southwest"
		SE: return "Southeast"
