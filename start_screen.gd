extends Node2D

@onready var start_button: Button = $CanvasLayer/Menu/StartButton
@onready var start_effect: ColorRect = $CanvasLayer/StartEffect
var start_input_position = null

func _ready():
	flash_start_button()

func _process(_delta: float) -> void:
	if Input.is_action_pressed("ui_accept") and start_input_position == null:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			start_input_position = get_viewport().get_mouse_position()
		else:
			start_input_position = start_effect.get_global_rect().size / 2.0
	elif start_input_position != null:
		start_effect.modulate = Color(1,1,1,1)
		activate_shader_effect_at(start_effect, start_input_position)
		await get_tree().create_timer(0.9).timeout
		Global.goto_scene(Global.WORLD_SCENE_PATH)

func flash_start_button():
	var tween = create_tween()
	tween.set_loops()  # Infinite loop
	tween.tween_property(start_button, "modulate:a", 0.3, 0.8)
	tween.tween_property(start_button, "modulate:a", 1.0, 0.8)

func activate_shader_effect_at(cr: ColorRect, screen_pos: Vector2) -> void:
	var global_rect := cr.get_global_rect() # Rect2, in screen coords
	var local: Vector2 = screen_pos - global_rect.position
	var uv: Vector2 = local / global_rect.size
	cr.material.set_shader_parameter("texture_center", uv)
	cr.modulate = Color(1,1,1,1)
