extends Area2D
@onready var outer_ring: Sprite2D = $OuterRing
@onready var mid_ring: Sprite2D = $MidRing
@onready var inner_ring: Sprite2D = $InnerRing
var _rings: Array[Sprite2D]

const FADE_OUT_TARGET = Color(Color.WHITE, 0.0)
const INNER_TARGET = Color(Color.WHITE, 0.6)
const MID_TARGET = Color(Color.WHITE, 0.4)
const OUTER_TARGET = Color(Color.WHITE, 0.2)

var _fade_tween: Tween = null 

func _ready() -> void:
	_rings = [inner_ring, mid_ring, outer_ring]

func _fade_to_out_in(aim_pos: Vector2) -> void:
	if global_position != aim_pos:
		await _fade_out()
		global_position = aim_pos
		await _fade_in()  # uses staggered durations

func _fade_out(dur := 0.1) -> void:
	_kill_fade_tween()
	_fade_tween = create_tween().set_parallel(true)

	for ring in _rings:
		_fade_tween.tween_property(ring, "modulate", FADE_OUT_TARGET, dur).from_current()
	await _fade_tween.finished
	for ring in _rings:
		ring.modulate = FADE_OUT_TARGET

func _fade_in() -> void:
	_kill_fade_tween()
	_fade_tween = create_tween().set_parallel(true)
	_fade_tween.tween_property(inner_ring, "modulate", INNER_TARGET, 0.1).from_current()
	_fade_tween.tween_property(mid_ring,   "modulate", MID_TARGET,   0.3).from_current()
	_fade_tween.tween_property(outer_ring, "modulate", OUTER_TARGET, 0.6).from_current()
	await _fade_tween.finished

func _kill_fade_tween() -> void:
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()   # stops without emitting 'finished'
	_fade_tween = null
	
func tween_fade_to_target(aim_pos: Vector2) -> void:
	_fade_to_out_in(aim_pos)

func fade_out(duration := 0.1) -> void:
	_fade_out(duration)
