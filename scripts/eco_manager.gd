extends Node
@onready var save_data := Save.data as SaveData
signal energy_gained(e: float, f: float, d: float, c: float)

func _ready() -> void:
	# Initialize ticker
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.one_shot = false
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(_on_tick)

func _on_tick() -> void:
	var g = 0
	var a = 0
	var p = 0
	var t = 0
	for plant in  Global.save_data.plants: 
		if plant.is_revived:
			g += plant.get_glycosine_per_tick()
			a += plant.get_alkaline_per_tick()
			p += plant.get_poly_per_tick()
			t += plant.get_terpine_per_tick()
	add_energy(g, a, p, t)

func add_energy(g, a = 0, p = 0, t = 0):
	save_data.energy_g += g
	save_data.energy_a += a
	save_data.energy_p += p
	save_data.energy_t += t
	Save.save_game()
	emit_signal(Global.TICK_SIGNAL, g,a,p,t)

func subtract_energy(g, a = 0, p = 0, t = 0):
	save_data.energy_g -= g
	save_data.energy_a -= a
	save_data.energy_p -= p
	save_data.energy_t -= t
	Save.save_game()
