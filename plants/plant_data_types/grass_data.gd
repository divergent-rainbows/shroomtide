extends PlantData
class_name GrassData

# Plant level represents overall maturity
@export var max_level : int
@export var level := 0

# Plant can be composed of multiple spawns
@export var max_spawns := 5
@export var spawns: Array[Array] = []
@export var jitter: float = 2.5

# Spawn can be composed of multiple foliage
# represented by an int that corresponds to 
# a frame in a growth animation
@export var max_foliage := 7

# Spawns emerge depending on plant levels
@export var spawn_emerge_level = [1,2,3,5,8] 

# Blades emerge at the relative spawn level 
# (see calc_spawn_level)
@export var blade_emerge_stage = [1,3,5,9,13,15]

# Randomize the order in spawns emerge 
var growth_order : Array
var spawn_visuals : Array[Node] 

# Add shade for depth
const SHADED_POS_RULES := {0: [1, 2], 1: [3], 2: [4]}
const BLADE_COUNT_FOR_SHADE := 3
const BASE_DARKEN := 0.1

func _init() -> void:
	growth_order = range(max_spawns) 
	growth_order.shuffle()

func get_health_status() -> Global.HealthStatus:
	if not is_in_network:
		return Global.HealthStatus.Unknown
	elif not is_revived:
		return Global.HealthStatus.Dead

	match level:
		_ when level >15:
			return Global.HealthStatus.Recovered
		_ :
			return Global.HealthStatus.Healing

func on_tile_ready(plant_area: Node, tile_root: Node) -> void:
	_plant_area = plant_area
	_tile_root = tile_root
	var sprites := tile_root.get_children()
	for s in sprites:
		var off = Vector2(randf_range(-jitter, jitter), randf_range(-jitter, jitter))
		s.position += off
	self.spawn_visuals = sprites

func update_visuals():
	# Progress spawn stages
	for i in range(spawn_visuals.size()):
		var pos = growth_order[i]
		var spawn = spawn_visuals[pos]
		var blades = spawn.get_children()
		for j in range(blades.size()):
			var blade: AnimatedSprite2D = blades[j]
			if spawns.size() > i and spawns[i].size() > j:
				blade.frame = spawns[i][j]
				spawn.show()
				blade.show()
			else:
				blade.frame = 0

	# Apply shading mods
	for i in range(spawn_visuals.size()):
		var shaded = SHADED_POS_RULES.get(i)
		var spawn_idx = growth_order[i]
		if shaded != null and spawn_idx < spawns.size():
			var shading_spawn = spawns[spawn_idx]
			var blade_size = min(shading_spawn.max(), 7)
			var size_factor = max(blade_size - BLADE_COUNT_FOR_SHADE, 0)
			for shaded_pos in shaded:
				var shaded_sprite = spawn_visuals[shaded_pos]
				var dark_factor = BASE_DARKEN * size_factor * (i + 1) / 5
				shaded_sprite.modulate = Color.WHITE.darkened(dark_factor)

## Apply growth logic to the active spawn instances.
## Default = do nothing.
func grow() -> bool:
	if Eco.subtract_energy(get_new_leaf_cost()):
		leaves.append(sides.pick_random())
		
		for i in range(spawns.size()):
			for j in range(spawns[i].size()):
				spawns[i][j] += 1
		level += 1
	
		if spawns.size() < max_spawns:
			show_new_spawn()
		for idx in range(spawns.size()):
			if spawns[idx].size() < max_foliage:
				show_new_blade(idx)
		update_visuals()
		return true
	else: return false

func calc_spawn_level(spawn_idx: int) -> int:
	return level - (spawn_emerge_level[spawn_idx] - 1)

# Show new spawns by incrementing the first foliage
func show_new_spawn():
	if level in spawn_emerge_level:
		spawns.append([]) # new spawn

func show_new_blade(spawn_idx):
	var spawn = spawns[spawn_idx]
	if calc_spawn_level(spawn_idx) in blade_emerge_stage:
		spawn.append(0) # new blade

# Show new spawns by incrementing the first foliage
func show_new_spawns():
	for spawn_idx in range(spawns.size()):
		var spawn = spawns[spawn_idx]
		if spawn_emerge_level[spawn_idx] <= level \
			and spawn[0][0] == 0: 	# is hidden
				spawn[0][0] += 1 	# show first blade
