extends Control

const CONNECT = "Connect"
const INSPECT = "Inspect"
const NURTURE = "Nurture"
const REVIVE = "Revive"
const GROW_LEAF = "Grow Leaf"
const BACK = "Back"
@onready var plant_area: Area2D = $".."
@onready var message: Control = $"../Message"
@onready var save_data := Save.data as SaveData

var pd := Global.current_plant_data as PlantData

func _process(_delta: float) -> void: 
	pd = Global.current_plant_data
	if pd == null:
		return
	
	# Default Menu Options
		# Dynamic button
	$Top/Action.text = CONNECT
	$Top/Cost.text = "-%d" % pd.get_connect_cost()
	# Dynamic button
	$Left/Action.text = REVIVE
	$Left/Cost.text = "-%d" % pd.get_revive_cost()
	# Not Dynamic
	$Right/Action.text = GROW_LEAF
	$Right/Cost.text = "-%d" % pd.get_new_leaf_cost()
	# Not Dynamic
	$Bottom/Action.text = BACK
	$Bottom/Cost.hide()
	
	# Once Connected, Connect => Inspect
	# Hide Revive and Grow actions until connected
	if pd.is_in_network:
		$Top/Action.text = INSPECT
		$Top/Cost.hide()
		$Left.show()
		$Right.show()
	else:
		$Top/Cost.show()
		$Left.hide()
		$Right.hide()
	
	# Once Revived, Revived => Nurture 
	# Hide Grow until revived
	if pd.is_revived:
		$Left/Action.text = NURTURE
		$Left/Cost.text = "-%d" % pd.get_nurture_cost()
		$Right.show()
	else:
		$Right.hide()


func _on_left_pressed() -> void:
	match $Left/Action.text:
		NURTURE:
			var cost = pd.get_nurture_cost()
			if save_data.energy_g >= cost:
				Eco.subtract_energy(cost)
				Global.control_override = false
				Global.goto_scene(Global.PLATFORMER_SCENE_PATH)
			else: 
				message.show_message('Wait for enough energy')

		REVIVE:
			var cost = pd.get_revive_cost()
			if save_data.energy_g >= cost:
				Eco.subtract_energy(cost)
				pd.is_revived = true
				message.show_message("Plant is revived!")
			else: 
				message.show_message("Need more energy.")


func _on_right_pressed() -> void:
	var side = [Global.LeafPosition.Left, Global.LeafPosition.Right]
	var new_leaf_cost = pd.get_new_leaf_cost()
	if save_data.energy_g > new_leaf_cost:
		pd.leaves.append(side.pick_random())
		Eco.subtract_energy(new_leaf_cost)
		message.show_message('Plant grew a new leaf!')
	else:
		message.show_message('Not enough energy...')

func _on_bottom_pressed() -> void:
	plant_area.is_selected = false
	Global.control_override = false
	self.hide()

func _on_top_pressed() -> void:
	match $Top/Action.text:
		CONNECT:
			if not pd.is_in_network and save_data.energy_g > pd.network_cost:
				Eco.subtract_energy(pd.network_cost)
				pd.is_in_network = true
				message.show_message('Plant is now in fungal network!', 3.0)
		INSPECT:
			message.show_message(pd.get_info(), 5.0)
