extends Control

@onready var timer_label: RichTextLabel = %TimeDisplay
@onready var g: RichTextLabel = %Resource
@onready var header: HBoxContainer = %Header

@onready var game_over_screen: VBoxContainer = $GameOverScreen
@onready var game_over: Label = $GameOverScreen/GameOver
@onready var final_time: Label = $GameOverScreen/FinalTime
@onready var final_message: Label = $GameOverScreen/FinalMessage

var level_data : LevelSaveData
const COMPOUND_SUCCESS = "complete"

func _ready():
	level_data = Save.get_current_level_data()
	show()
	_update()
	Global.tick.connect(_update)
	Global.game_complete.connect(_show_end_of_game)

func _update():
	_update_timer()
	var amount_g = level_data.energy_g
	g.text = Eco.format_number(amount_g, ',')

func _update_timer():
	var minutes = level_data.run_time / 60
	var seconds = int(level_data.run_time) % 60
	timer_label.text = "%d:%02d" % [minutes, seconds]
	
func _show_end_of_game():
	header.hide()

	var minutes = level_data.run_time / 60
	var seconds = int(level_data.run_time) % 60
	final_time.text = "Final Time: %d:%02d" % [minutes, seconds]
	game_over_screen.show()


func _on_reset_data_pressed() -> void:
	InputManager._on_reset_pressed()


func _on_back_to_start_screen_pressed() -> void:
	InputManager._on_back_to_start_screen_pressed()	


func _on_refresh_pressed() -> void:
	InputManager._on_refresh_pressed()


func _on_add_energy_pressed() -> void:
	Eco.add_energy(10000)


func _on_next_level_button_down() -> void:
	Save.next_level()
	InputManager._on_refresh_pressed()
