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
	_activate_shader_effect_at(screen_pos)
	await get_tree().create_timer(0.9).timeout
	Global.goto_scene(Global.WORLD_SCENE_PATH)

func _on_accept():
	var start_input_position = start_effect.get_global_rect().size / 2.0
	_activate_shader_effect_at(start_input_position)
	await get_tree().create_timer(0.9).timeout
	Global.goto_scene(Global.WORLD_SCENE_PATH)

func _flash_start_button():
	var tween = create_tween()
	tween.set_loops()  # Infinite loop
	tween.tween_property(start_button, "modulate:a", 0.3, 0.8)
	tween.tween_property(start_button, "modulate:a", 1.0, 0.8)

func _activate_shader_effect_at(screen_pos: Vector2) -> void:
	var global_rect := start_effect.get_global_rect() # Rect2, in screen coords
	var local: Vector2 = screen_pos - global_rect.position
	var uv: Vector2 = local / global_rect.size
	start_effect.material.set_shader_parameter("texture_center", uv)
	start_effect.modulate = Color(1,1,1,1)
