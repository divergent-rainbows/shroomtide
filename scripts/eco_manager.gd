extends Node
signal resources_changed()

func _ready() -> void:
	Global.tick.connect(_on_tick)

func _on_tick() -> void:
	add_energy(get_tick_energy())
	
func get_tick_energy():
	var energy = 0.0
	for plant in Save.get_current_level_data().plants: 
		if plant.is_revived:
			energy += plant.get_glycosine_per_tick()
	return energy

func add_energy(g):
	Save.get_current_level_data().energy_g += g
	Save.save_game()
	resources_changed.emit()

func has_energy(g) -> bool:
	return g <= Save.get_current_level_data().energy_g

func subtract_energy(g) -> bool:
	Save.get_current_level_data().energy_g -= g
	Save.save_game()
	resources_changed.emit()
	return true
	
## Insert delimeter every 3 digits from right to left
func format_number(n: float, delimiter: String = ",") -> String:
	var display = str(floori(n))
	var num_digits = display.length()
	var num_commas = floor((num_digits-1)/ 3.0)
	
	for i in range(num_commas):
		var pos = num_digits - (i+1)*3
		display = display.insert(pos, delimiter)
	return display

## Currently only handles thousands, not millions
func short_format(n: float) -> String:
	var digits = format_number(n)
	var display
	if len(digits) > 3:
		var k = digits.get_slice(",", 0)
		var remainder = int(digits.get_slice(",", 1))
		var h = floor(remainder / 100.0) 
		display = "%s.%sk" % [k, h]
	else:
		display = digits
	return display
