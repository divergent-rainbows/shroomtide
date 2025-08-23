extends Control

@onready var save_data := Save.data as SaveData
@onready var g: RichTextLabel = $Header/Stats/Resource

@onready var timer_label: RichTextLabel = $Header/Stats/TimeDisplay
@onready var game_over_screen: VBoxContainer = $GameOverScreen
@onready var game_over: Label = $GameOverScreen/GameOver
@onready var final_time: Label = $GameOverScreen/FinalTime
@onready var final_message: Label = $GameOverScreen/FinalMessage

const G_LABEL = "Glycosine"
const A_LABEL = "Alkaloid"
const P_LABEL = "Polyphenol"
const T_LABEL = "Terpene"
const G_SYMBOL = "G"

const COMPOUND_SUCCESS = "complete"

func _ready():
	update()

func update():
	update_timer()
	
	var amount_g = save_data.energy_g
	
	g.text = "%s: %.1f" % [G_SYMBOL, amount_g]
	if save_data.energy_g > Global.G_MAX:
		g.text = "%s - %s" % [G_SYMBOL, COMPOUND_SUCCESS]

func update_timer():
	var minutes = Save.data.run_time / 60
	var seconds = int(Save.data.run_time) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]
	
func show_end_of_game():
	timer_label.hide()
	g.hide()

	var minutes = Save.data.run_time / 60
	var seconds = int(Save.data.run_time) % 60
	final_time.text = "Final Time: %02d:%02d" % [minutes, seconds]
	game_over_screen.show()
	
	
