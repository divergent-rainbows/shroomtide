extends Control

@onready var timer: Timer = $Timer
@onready var g: Label = $G
@onready var a: Label = $A
@onready var p: Label = $P
@onready var t: Label = $T

func _ready():
	Eco.energy_gained.connect(_on_energy_gained)

func _on_timer_timeout() -> void:
	g.hide()
	a.hide()
	p.hide()
	t.hide()

func _on_energy_gained(e: float, f: float, d: float, c: float):
	g.text = "+%.2f" % e
	g.show()
	
	a.text = "+%.2f" % f
	if f != 0:
		a.show()
	
	p.text = "+%.2f" % d
	if d != 0:
		p.show()
	
	t.text = "+%.2f" % c
	if c != 0:
		t.show()
	
	timer.start(.2)
