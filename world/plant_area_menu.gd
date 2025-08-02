extends Control

# Action menu layout
enum BtnPos {TOP, BTM, LEFT, RIGHT}
# Action settings
enum {DISPLAY, EXECUTE, COST_FN}
# UI Nodes 
enum {ACTION_LABEL, COST_LABEL}

# Inspector message
const REVIVE_SUCCESS = "Plant is revived!"
const GROWTH_SUCCESS = "Plant grew a new leaf!"
const CONNECT_SUCCESS = "Plant is now in fungal network!"
const NOT_ENOUGH_RES = "Not enough energy..."

@onready var plant_area: Area2D = $".."
@onready var message: Control = $"../Message"

@onready var UI_NODES = {
	BtnPos.TOP: {
		ACTION_LABEL: $Top/Action,
		COST_LABEL: $Top/Cost
	},
	BtnPos.LEFT: {
		ACTION_LABEL: $Left/Action,
		COST_LABEL: $Left/Cost,
	},	
	BtnPos.RIGHT: {
		ACTION_LABEL: $Right/Action,
		COST_LABEL: $Right/Cost,
	},
	BtnPos.BTM: {
		ACTION_LABEL: $Bottom/Action,
		COST_LABEL: $Bottom/Cost,
	}
}

@onready var ACTION_CONFIG = {
	Global.HealthStatus.Unknown: {
		BtnPos.TOP: ACTION_CONNECT,	
	},
	Global.HealthStatus.Dead: {
		BtnPos.TOP: ACTION_INSPECT,
		BtnPos.LEFT: ACTION_REVIVE
	},
	Global.HealthStatus.Healing: {
		BtnPos.TOP: ACTION_INSPECT,
		BtnPos.LEFT: ACTION_NURTURE,
		BtnPos.RIGHT: ACTION_GROW_LEAF
	},
	Global.HealthStatus.Recovered: {
		BtnPos.TOP: ACTION_INSPECT,
		BtnPos.LEFT: ACTION_NURTURE,
		BtnPos.RIGHT: ACTION_GROW_LEAF
	}
}

@onready var pd := Global.current_plant_data as PlantData
@onready var save_data := Save.data as SaveData

func _ready() -> void:
	# Add Back button to each menu state
	for health_state_config in ACTION_CONFIG.keys():
		ACTION_CONFIG[health_state_config][BtnPos.BTM] = ACTION_BACK

func _process(_delta: float) -> void: 
	pd = Global.current_plant_data
	if pd != null: 
		var health = pd.get_health_status()
		for btn in BtnPos.values():
			set_action(btn, health) 
			set_cost(btn)

func _on_left_pressed() -> void:
	ACTION_CONFIG[pd.get_health_status()][BtnPos.LEFT][EXECUTE].call()

func _on_right_pressed() -> void:
	ACTION_CONFIG[pd.get_health_status()][BtnPos.RIGHT][EXECUTE].call()

func _on_bottom_pressed() -> void:
	ACTION_CONFIG[pd.get_health_status()][BtnPos.BTM][EXECUTE].call()

func _on_top_pressed() -> void:
	ACTION_CONFIG[pd.get_health_status()][BtnPos.TOP][EXECUTE].call()

	
func set_action(b: BtnPos, h: Global.HealthStatus) -> void:
	var menu_state = ACTION_CONFIG[h]
	# Check if action applies to this plant
	if menu_state != null and b in menu_state: 
		UI_NODES[b][ACTION_LABEL].text = menu_state[b][DISPLAY]
		UI_NODES[b][ACTION_LABEL].show()
	else: 
		UI_NODES[b][ACTION_LABEL].hide()

func set_cost(b:BtnPos) -> void:
	var menu_state = ACTION_CONFIG[pd.get_health_status()]
	# Check if action applies to this plant
	if menu_state != null and b in menu_state \
		 # Additionally, check if the action has a cost
		and COST_FN in menu_state[b]:
			UI_NODES[b][COST_LABEL].text = format_cost(menu_state[b][COST_FN].call(pd))
			UI_NODES[b][COST_LABEL].show()
	else: 
		UI_NODES[b][COST_LABEL].hide()

func format_cost(c):
	return "-%d" % c

# ACTIONS
### Connect
var ACTION_CONNECT = {
	DISPLAY: 'Connect',
	EXECUTE: Callable(self, "execute_connect"),
	COST_FN: func(p: PlantData): return p.get_connect_cost()
}
func execute_connect():
	pd = Global.current_plant_data
	save_data = Save.data
	if not pd.is_in_network and save_data.energy_g > pd.network_cost:
		Eco.subtract_energy(pd.network_cost)
		pd.is_in_network = true
		message.show_inspection(CONNECT_SUCCESS)
	else:
		message.show_inspection(NOT_ENOUGH_RES) # assumes not pd.is_in_net_work

### Inspect
var ACTION_INSPECT = {
	DISPLAY: 'Inspect',
	EXECUTE: Callable(self, "execute_inspect"),
}
func execute_inspect():
	message.show_inspection(pd.get_info())
	
### Grow Leaf
var ACTION_GROW_LEAF = {
	DISPLAY: 'Grow Leaf',
	EXECUTE: Callable(self, "execute_grow_leaf"),
	COST_FN: func(p: PlantData): return p.get_new_leaf_cost()
}
func execute_grow_leaf():
	pd = Global.current_plant_data
	var side = [Global.LeafPosition.Left, Global.LeafPosition.Right]
	var new_leaf_cost = pd.get_new_leaf_cost()
	if save_data.energy_g > new_leaf_cost:
		pd.leaves.append(side.pick_random())
		Eco.subtract_energy(new_leaf_cost)
		message.show_inspection(GROWTH_SUCCESS)
	else:
		message.show_inspection(NOT_ENOUGH_RES)

### Nurture
var ACTION_NURTURE = {
	DISPLAY: 'Nurture',
	EXECUTE: Callable(self, "execute_nurture"),
	COST_FN: func(p: PlantData): return p.get_nurture_cost()
}
func execute_nurture():
	pd = Global.current_plant_data
	var cost = pd.get_nurture_cost()
	if save_data.energy_g >= cost:
		Eco.subtract_energy(cost)
		plant_area.is_selected = false
		Global.control_override = false
		Global.goto_scene(Global.PLATFORMER_SCENE_PATH)
	else: 
		message.show_inspection(NOT_ENOUGH_RES)

### Revive
var ACTION_REVIVE = {
	DISPLAY: 'Revive',
	EXECUTE: Callable(self, "execute_revive"),
	COST_FN: func(p: PlantData): return p.get_revive_cost()
}
func execute_revive():
	pd = Global.current_plant_data
	var cost = pd.get_revive_cost()
	if save_data.energy_g >= cost:
		Eco.subtract_energy(cost)
		pd.is_revived = true
		message.show_inspection(REVIVE_SUCCESS)
	else: 
		message.show_inspection(NOT_ENOUGH_RES)

### Back
var ACTION_BACK = {
	DISPLAY: 'Back',
	EXECUTE: Callable(self, "execute_back"),
}
func execute_back():
	plant_area.is_selected = false
	Global.control_override = false
	self.hide()
		
