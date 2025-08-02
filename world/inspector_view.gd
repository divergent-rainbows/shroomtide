extends Control

@onready var label: Label = $Label
@onready var timer: Timer = $Timer

func show_inspection(text, stall = 2.0):
	label.text = text
	label.show()
	timer.start(stall)

func _on_timer_timeout() -> void:
	label.hide()
