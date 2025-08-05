extends Control

@onready var save_data := Save.data as SaveData
@onready var g: RichTextLabel = $G
@onready var a: RichTextLabel = $A
@onready var p: RichTextLabel = $P
@onready var t: RichTextLabel = $T
@onready var timer_label: RichTextLabel = $TimeDisplay
@onready var game_over_screen: CanvasLayer = $GameOverScreen
@onready var final_time: RichTextLabel = $GameOverScreen/FinalTime

const G_LABEL = "Glycosine"
const A_LABEL = "Alkaloid"
const P_LABEL = "Polyphenol"
const T_LABEL = "Terpene"
const G_SYMBOL = "G"
const A_SYMBOL = "A"
const P_SYMBOL = "P"
const T_SYMBOL = "T"
const COMPOUND_SUCCESS = "complete"

func _ready():
	update()

func update():
	update_timer()
	
	var amount_g = save_data.energy_g
	var amount_a = save_data.energy_a
	var amount_p = save_data.energy_p
	var amount_t = save_data.energy_t
	
	g.text = "%s: %.1f" % [G_SYMBOL, amount_g]
	if save_data.energy_g > Global.G_MAX:
		g.text = "%s - %s" % [G_SYMBOL, COMPOUND_SUCCESS]

	a.text = "%s: %.1f" % [A_SYMBOL, amount_a]
	if amount_a > Global.A_MAX:
		a.text = "%s - %s" % [A_SYMBOL, COMPOUND_SUCCESS]
	if amount_a != 0:
		a.show()
	
	p.text = "%s: %.1f" % [P_SYMBOL, amount_p]
	if amount_a > Global.P_MAX:
		p.text = "%s - %s" % [P_SYMBOL, COMPOUND_SUCCESS]
	if amount_p != 0:
		p.show()
	
	t.text = "%s: %.1f" % [T_SYMBOL, amount_t]
	if amount_a > Global.T_MAX:
		t.text = "%s - %s" % [T_SYMBOL, COMPOUND_SUCCESS]
	if amount_t != 0:
		t.show()
	
func update_timer():
	var minutes = Save.data.run_time / 60
	var seconds = int(Save.data.run_time) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]
	
func show_end_of_game():
	timer_label.hide()
	g.hide()
	a.hide()
	p.hide()
	t.hide()
	var minutes = Save.data.run_time / 60
	var seconds = int(Save.data.run_time) % 60
	final_time.text = "Final Time: %02d:%02d" % [minutes, seconds]
	game_over_screen.show()
	
	
