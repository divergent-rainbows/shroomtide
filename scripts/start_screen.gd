extends Node2D

@onready var start_button: Button = $CanvasLayer/Menu/StartButton
@onready var start_effect: ColorRect = $CanvasLayer/StartEffect
@onready var vine: TileMapLayer = $CanvasLayer/Parallax2D2/Vine

func _ready():
	_on_resize()
	get_tree().root.size_changed.connect(_on_resize)
	_flash_start_button()
	InputManager.on_screen_touch.connect(_on_screen_tap)
	InputManager.accept.connect(_on_accept)
	
func _on_resize():
	var s := get_viewport().get_visible_rect().size
	vine.position = s * 0.5 

func _on_screen_tap(event) -> void:
	var screen_pos = event.position
	await _activate_shader_effect_at(screen_pos)
	Global.goto_scene(Global.WORLD_SCENE_PATH)

func _on_accept():
	var start_input_position = start_effect.get_global_rect().size / 2.0
	await _activate_shader_effect_at(start_input_position)
	Global.goto_scene(Global.WORLD_SCENE_PATH)

func _flash_start_button():
	var tween = create_tween()
	tween.set_loops()  # Infinite loop
	tween.tween_property(start_button, "modulate:a", 0.3, 0.8)
	tween.tween_property(start_button, "modulate:a", 1.0, 0.8)

func _activate_shader_effect_at(screen_pos: Vector2) -> Signal:
	var global_rect := start_effect.get_global_rect() # Rect2, in screen coords
	var local: Vector2 = screen_pos - global_rect.position
	var uv: Vector2 = local / global_rect.size
	start_effect.material.set_shader_parameter("texture_center", uv)
	start_effect.modulate = Color(1,1,1,1)

	# Create the ripple effect tween
	var tween = create_tween()
	tween.set_parallel(true)  # Allow multiple tweens to run simultaneously

	# Tween opaque radius from 0 to 1.0 over 2 seconds with ease_out quad
	tween.tween_property(start_effect.material, "shader_parameter/opaque_radius", 1.2, 2.2) \
		 .from(0.0) \
		 .set_trans(Tween.TRANS_LINEAR)

	# Tween ring thickness from 0.05 to 0.3 over 2 seconds with ease_out quad
	tween.tween_property(start_effect.material, "shader_parameter/ring_thickness", 0.3, 2) \
		 .from(0.05) \
		 .set_ease(Tween.EASE_OUT) \
		 .set_trans(Tween.TRANS_QUAD)
		
	return tween.finished
