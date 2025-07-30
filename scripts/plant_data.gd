extends Resource
class_name PlantData

const PHYTOCHEMICAL_STRING = {
	
}

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
@export var is_in_network: bool = false # to fungal network
@export var network_cost: int = 10
@export var is_revived: bool = false
@export var revive_cost: int = 20

@export var nurture_cost: int = 2
@export var leaf_cost_basis: int = 10
@export var leaves: Array[Global.LeafPosition]

# yield coefficient
@export var photosynthesis_rate: float = 0.12
@export var a_rate: float = 0
@export var p_rate: float = 0
@export var t_rate: float = 0

@export var run_multiplier: int = 5
@export var max_num_leaves: int # maximum number of leaves 

@export var height_reached: float
@export var leaves_reached: int
@export var total_runs: int = 0

#haven't got to yet 
@export var growth_rate: float # number of new leaves

func set_tree_defaults():
	leaves = get_random_leaves(50, 100)
	type = Global.PlantType.Trees
	network_cost = 50
	revive_cost = 35
	nurture_cost = 10
	leaf_cost_basis = 5
	photosynthesis_rate = 0.7
	a_rate = 0.4
	p_rate = 0.5
	t_rate = 0.3
	run_multiplier = 10

func set_shrub_a_defaults():
	leaves = get_random_leaves(20, 35)
	const comound_rates = {
		0: {
			"g": 0.3,
			"a": 0.2,
			"p": 0.0,
			"t": 0.0
		},
		1: {
			"g": 0.3,
			"a": 0.0,
			"p": 0.1,
			"t": 0.1
		}
	}
	type = Global.PlantType.Shrub
	network_cost = 50
	revive_cost = 35
	nurture_cost = 10
	leaf_cost_basis = 5
	photosynthesis_rate = 0.3
	a_rate = 0.2
	run_multiplier = 10

func set_shrub_b_defaults():
	leaves = get_random_leaves(20, 35)
	type = Global.PlantType.Shrub
	network_cost = 50
	revive_cost = 35
	nurture_cost = 10
	leaf_cost_basis = 5
	photosynthesis_rate = 0.3
	p_rate = 0.1
	t_rate = 0.1
	run_multiplier = 10


func get_alkaline_per_tick():
	return  get_leaf_count() * a_rate

func get_poly_per_tick():
	return get_leaf_count() * a_rate
func get_terpine_per_tick():
	return get_leaf_count() * t_rate

static func get_random_leaves(c: int = 2, d: int = 6) -> Array[Global.LeafPosition]:
	var side = [Global.LeafPosition.Left, Global.LeafPosition.Right]
	var initial_leaf_count = range(c,d).pick_random() 
	var genned_leaves := [] as  Array[Global.LeafPosition]
	for i in range(initial_leaf_count):
		genned_leaves.append(side.pick_random())
	return genned_leaves

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
func get_health_status() -> Global.HealthStatus:
	# placeholder logic
	if not is_revived:
		return Global.HealthStatus.Dead
	elif total_runs < 3:
		return Global.HealthStatus.Healing
	else:
		return Global.HealthStatus.Recovered

func get_info():
	return "%s has %d leaves\nGlycosine Rate: %.2f" % [PLANT_TYPE_STRING[type],  get_leaf_count(), photosynthesis_rate] 

func get_rand_info():
	print_info()
	var infos = [
		'There\'s %d leaves!' % get_leaf_count(),
		#'This plant is %s' % health_str[get_health_status()],
		#'You cleared the first %d of this plant.' % height_reached,
		#'Each leaf produces %d energy' % photosynthesis_rate,
		#'A new leaf will cost %d' % min(leaf_cost_basis*get_leaf_count(), leaf_cost_max),
	]
	return infos.pick_random()

func print_info():
	print("Plant ID: \t", id)
	print("In Network: \t", is_in_network, "\t", network_cost)
	print("Alive: \t", is_revived, "\t", revive_cost)
	print("Health: \t", HEALTH_STRING[get_health_status()])
	print("LeafCount:\t", get_leaf_count())
	print("LeafCost: \t", leaf_cost_basis)
	print("PhoSynRate:\t", photosynthesis_rate)
	print("HighScore:\t", height_reached)
	print("Leaves:\t", leaves_reached)
	#print("Growth Rate:", growth_rate)
	#print("Leaf Positions:")
	#for i in leaves.size():
		#print("  - Leaf", i, ":", leaves[i])
	print("\n")
