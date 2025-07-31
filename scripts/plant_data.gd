extends Resource
class_name PlantData

const HEALTH_STRING = {
	Global.HealthStatus.Dead: 'dying',
	Global.HealthStatus.Healing: 'on the mend',
	Global.HealthStatus.Recovered: 'happy'
}

const PLANT_TYPE_STRING = {
	Global.PlantType.Stalk: 'Stalk',
	Global.PlantType.Shrub: 'Shrub',
	Global.PlantType.Trees: 'Tree'
}

@export var id: int
@export var type: Global.PlantType 
@export var is_in_network: bool = false
@export var is_revived: bool = false
@export var num_healthy_leaves: int = 0
@export var max_healthy_leaves: int = 0

@export var network_cost: int 
@export var revive_cost: int 
@export var nurture_cost: int
@export var leaf_cost_basis: int 

@export var initial_leaf_count: int 
@export var leaves: Array[Global.LeafPosition]

# yield coefficient
@export var g_rate: float
@export var a_rate: float
@export var p_rate: float
@export var t_rate: float 

@export var run_multiplier: int = 5
@export var max_num_leaves: int # maximum number of leaves 

@export var height_reached: float
@export var leaves_reached: int
@export var total_runs: int = 0

@export var visual_scene: PackedScene

#haven't got to yet 
@export var growth_rate: float # number of new leaves
static var STALK_DEFAULT := load("res://plant_types/stalks_default.tres")
static var SHRUB_DEFAULT := load("res://plant_types/shrubs_default.tres")
static var TREE_DEFAULT := load("res://plant_types/trees_default.tres")

static func create(plant_type: Global.PlantType) -> PlantData:
	var plant = PlantData.new()
	match plant_type:
		Global.PlantType.Stalk:
			plant = STALK_DEFAULT.duplicate(true)
		Global.PlantType.Shrub:
			plant = SHRUB_DEFAULT.duplicate(true)
		Global.PlantType.Trees:
			plant = TREE_DEFAULT.duplicate(true)
		_: 
			assert(false, "PlantType: %s has not been implemented yet")
	plant.generate_random_leaves()
	return plant

func get_glycosine_per_tick():
	return  get_leaf_count() * g_rate
func get_alkaline_per_tick():
	return  get_leaf_count() * a_rate
func get_poly_per_tick():
	return get_leaf_count() * a_rate
func get_terpine_per_tick():
	return get_leaf_count() * t_rate

func generate_random_leaves():
	var sides = [Global.LeafPosition.Left, Global.LeafPosition.Right]
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

# Health = demand / supply ,
# demand = the amount of resources the plant can consume 
# supply = the amount of resources made available to the plant 
# Health = % based on completion
# num_healthy_leaves / num_healthy_leaves_required
func get_health_status() -> Global.HealthStatus:
	# placeholder logic
	if not is_revived:
		return Global.HealthStatus.Dead
	elif get_leaf_count() < max_num_leaves:
		return Global.HealthStatus.Healing
	else:
		return Global.HealthStatus.Recovered

func get_info():
	return "%s has %d leaves\nGlycosine Rate: %.2f" % [PLANT_TYPE_STRING[type],  get_leaf_count(), g_rate] 

func stringify_type() -> String:
	return PLANT_TYPE_STRING[type]
