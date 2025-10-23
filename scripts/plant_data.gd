extends Resource
class_name PlantData

const HEALTH_STRING = {
	Global.HealthStatus.Unknown: 'unknown',
	Global.HealthStatus.Dead: 'dying',
	Global.HealthStatus.Healing: 'on the mend',
	Global.HealthStatus.Recovered: 'happy'
}

const PLANT_TYPE_STRING = {
	Global.PlantType.Grass: 'Grass',
	Global.PlantType.Stalk: 'Stalk',
	Global.PlantType.Shrub: 'Shrub',
	Global.PlantType.Trees: 'Tree'
}

@export var id: int
@export var type: Global.PlantType 
@export var is_in_network: bool = false
@export var is_revived: bool = false

@export var network_cost: int 
@export var revive_cost: int 
@export var nurture_cost: int
@export var leaf_cost_basis: int 

@export var initial_leaf_count: int 
@export var leaves: Array[Global.LeafPosition]

# yield coefficient
@export var g_rate: float

@export var run_multiplier: int = 5
@export var max_num_leaves: int # maximum number of leaves 

@export var tile := preload("res://plants/scenes/plant_area.tscn")
@export var visual_scene: PackedScene
var _plant_area: PlantArea
var _tile_root: Node
var _network: MyceliumNetwork

static var STALK_DEFAULT := load("res://plants/default_values/stalks_default.tres")
static var SHRUB_DEFAULT := load("res://plants/default_values/shrubs_default.tres")
static var TREE_DEFAULT := load("res://plants/default_values/trees_default.tres")
static var GRASS_DEFAULT := load("res://plants/default_values/grass_default.tres")

const sides = [Global.LeafPosition.Left, Global.LeafPosition.Right]

static func create_from_type(plant_type: Global.PlantType) -> PlantData:
	var plant : PlantData
	match plant_type:
		Global.PlantType.Stalk:
			plant = STALK_DEFAULT.duplicate(true)
		Global.PlantType.Shrub:
			plant = SHRUB_DEFAULT.duplicate(true)
		Global.PlantType.Trees:
			plant = TREE_DEFAULT.duplicate(true)
		Global.PlantType.Grass:
			plant = GRASS_DEFAULT.duplicate(true)
		_: 
			assert(false, "PlantType: %s has not been implemented yet")
	plant.generate_random_leaves()
	return plant
	
func grow() -> bool:
	leaves.append(sides.pick_random())
	update_visuals()
	return true

func revive() -> bool:
	is_revived = true
	return true

func connect_to_network() -> bool:
	_network.create_connection(_plant_area.position)
	is_in_network = true
	return true

func get_health_percent() -> float:
	var health_percent = float(get_leaf_count()) / float(max_num_leaves)
	return min(health_percent, 1.0) 

func get_health_status() -> Global.HealthStatus:
	if not is_in_network:
		return Global.HealthStatus.Unknown
	elif not is_revived or get_health_percent() < 0.25 :
		return Global.HealthStatus.Dead
	elif get_health_percent() < 0.75 :
		return Global.HealthStatus.Healing
	elif get_health_percent() < 1.0:
		return Global.HealthStatus.Recovered
	else:
		return Global.HealthStatus.Thriving

func on_tile_ready(plant_area: Node, tile_root: Node) -> void:
	_plant_area = plant_area
	_tile_root = tile_root
	var states := {
		Global.HealthStatus.Unknown: _tile_root.get_node("Dead"),
		Global.HealthStatus.Dead:    _tile_root.get_node("Dead"),
		Global.HealthStatus.Healing: _tile_root.get_node("Healing"),
		Global.HealthStatus.Recovered:_tile_root.get_node("Recovered"),
		Global.HealthStatus.Thriving:_tile_root.get_node("Recovered"),
	}
	_plant_area.set("tile_states", states)

func update_visuals() -> void:
	# Default: show the sprite for current health
	var states: Dictionary = _plant_area.get("tile_states")
	if states:
		for n in states.values(): n.hide()
		var st = get_health_status()
		if states.has(st):
			states[st].show()
	if get_health_status() == Global.HealthStatus.Thriving:
		var glow = _tile_root.get_node("Glow")
		if glow: glow.show()

func get_glycosine_per_tick() -> float:
	return g_rate * get_health_percent() * get_health_status() / Global.TICK_GRAIN

func generate_random_leaves():
	leaves = []
	for i in range(initial_leaf_count):
		leaves.append(sides.pick_random())

func get_connect_cost():
	return 0 if is_in_network else network_cost
	
func get_revive_cost():
	return 0 if is_revived else revive_cost
	
func get_nurture_cost():
	return nurture_cost
	
func get_new_leaf_cost():
	return leaves.size() * leaf_cost_basis
	
func get_leaf_count():
	return leaves.size()
	
func get_nurture_time():
	return (get_leaf_count() / 2.0) + 5
	
func get_nurture_reward():
	return Eco.get_tick_energy() * get_health_status() * run_multiplier * Global.TICK_GRAIN

func get_info():
	for i in Save.data.plants_map.keys():
		var p = Save.data.plants_map[i]
		Console.log_format(i, ": %s, %s", [p.stringify_type(), p.stringify_health()])
	return "%s has %d leaves\nGlycosine Rate: %.2f" % [PLANT_TYPE_STRING[type],  get_leaf_count(), get_glycosine_per_tick()] 

func get_plant_id_str() -> String:
	return "%s-%s" % [stringify_type(), id]

func stringify_type() -> String:
	return PLANT_TYPE_STRING[type]

func stringify_health() -> String:
	return HEALTH_STRING[get_health_status()]
