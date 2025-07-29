extends Control

@onready var label: Label = $Label
@onready var timer: Timer = $Timer

func show_message(text, stall = 2.0):
	label.text = text
	label.show()
	timer.start(stall)
	print(text)

func _on_timer_timeout() -> void:
	label.hide()
