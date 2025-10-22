extends Resource
class_name PlantActionCost 

@export var requirements : = {'energy': 0}
var bb_code := "[img]" + "res://assets/svg/sun.svg" + "[/img]"

func can_pay() -> bool:
	return Eco.has_energy(requirements['energy'])

func pay() -> void:
	Eco.subtract_energy(requirements['energy'])

func to_button_display() -> String:
	var parts := []
	for k in requirements.keys():
		parts.append("%s %s" % [bb_code, str(requirements[k])])
	return ", ".join(parts)
