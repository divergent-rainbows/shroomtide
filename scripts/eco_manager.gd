extends Node
@onready var save_data := Save.data as SaveData
signal energy_gained(e: float, f: float, d: float, c: float)

func _ready() -> void:
	Global.tick.connect(_on_tick)

func _on_tick() -> void:
	var g = 0
	for plant in  Global.save_data.plants: 
		if plant.is_revived:
			g += plant.get_glycosine_per_tick()
	add_energy(g)
	
func get_tick_energy():
	var energy = 0
	for plant in  Global.save_data.plants: 
		if plant.is_revived:
			energy += plant.get_glycosine_per_tick()
	return energy

func add_energy(g):
	save_data.energy_g += g
	Save.save_game()
	emit_signal("energy_gained", g)

func subtract_energy(g) -> bool:
	if g <= save_data.energy_g:
		save_data.energy_g -= g
		Save.save_game()
		return true
	else:
		return false
	
