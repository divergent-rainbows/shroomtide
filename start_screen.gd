extends Node2D

@onready var start_button: Button = $CanvasLayer/Menu/StartButton

func _ready():
	flash_start_button()

func flash_start_button():
	var tween = create_tween()
	tween.set_loops()  # Infinite loop
	
	# Fade out
	tween.tween_property(start_button, "modulate:a", 0.3, 0.8)
	# Fade in  
	tween.tween_property(start_button, "modulate:a", 1.0, 0.8)

func _on_start_button_pressed() -> void:
	Global.goto_scene(Global.WORLD_SCENE_PATH)
