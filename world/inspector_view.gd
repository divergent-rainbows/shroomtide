extends Control
class_name InspectorView

signal inspect_started
@onready var action_menu: PlantActionMenu = $Panel/ActionMenu

@onready var inspect_button: TextureButton = $InspectButton
@onready var shroomie: Shroomie = %Shroomie
@onready var panel: TextureRect = $Panel
@onready var stats: InspectorStats = $Panel/StatsPanel/Stats

var _plant: PlantData

func _ready() -> void:
	show()
	inspect_button.hide()
	stats.hide()
	panel.hide()
	action_menu.hide()
	action_menu.action_executed.connect(_refresh)
	Global.game_complete.connect(_back)
	InputManager.on_screen_touch.connect(_back_if_no_button_pressed)
	InputManager.on_screen_drag.connect(_hide_inspect_button_when_moving)


func _back() -> void:
	inspect_button.button_pressed = false
	_on_inspect_button_toggled(false)
	inspect_button.hide()
	panel.hide()


func _pan_camera_to_tile(toggled_on: bool) -> Signal:
	var animation_duration := 0.3
	var tween = create_tween()
	tween.set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	var cam := get_viewport().get_camera_2d()
	if cam:
		var vp_h: float = get_viewport().get_visible_rect().size.y
		var local_h := vp_h / cam.zoom.y / scale.y
		#var world_shift_y: float = (vp_h * 0.5 - top_margin_px) / cam.zoom.y
		var s := local_h * 0.05
		var target_offset := Vector2(0, s) if toggled_on else Vector2.ZERO
		var target_zoom: Vector2 = Vector2.ONE * (Global.CAMERA_ZOOM * (2.0 if toggled_on else 1.0))
		var target_pos = _plant._plant_area.position if toggled_on else shroomie.global_position
		tween.tween_property(cam, "global_position", target_pos, animation_duration)
		tween.tween_property(cam, "offset", target_offset, animation_duration)
		tween.tween_property(cam, "zoom", target_zoom, animation_duration) 
	return tween.finished


func _on_inspect_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		await _pan_camera_to_tile(toggled_on)
		stats.visible = toggled_on
		action_menu.visible = toggled_on
		panel.visible = toggled_on
	else:
		panel.visible = toggled_on
		stats.visible = toggled_on
		action_menu.visible = toggled_on
		await _pan_camera_to_tile(toggled_on)
	Global.control_override = toggled_on


func _back_if_no_button_pressed(event) -> void:
	if not event.pressed:
		return
	var btns = action_menu.get_children()
	btns.append(inspect_button)
	var btn_pressed = false
	for btn in btns:
		if btn.get_global_rect().has_point(event.position): 
			btn_pressed = true
	if not btn_pressed:
		_back()
	

func _hide_inspect_button_when_moving(_event) -> void:
	if shroomie.is_moving:
		inspect_button.button_pressed = false
		inspect_button.hide()


func _rebuild():
	stats._rebuild(_plant)
	action_menu._rebuild(_plant)


func _refresh():
	stats._rebuild(_plant)
	action_menu._refresh_buttons(_plant)


func on_tile_hovered(tile: PlantArea):
	if not shroomie.is_moving:
		_plant = tile.plant_data
		_rebuild()
		inspect_button.show()
		inspect_button.grab_click_focus()
	if inspect_button.visible and tile.plant_data == _plant:
		_on_inspect_button_toggled(true)


func on_rehover():
	_rebuild()
	inspect_button.show()
	inspect_button.grab_click_focus()
