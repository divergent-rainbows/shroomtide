extends Sprite2D
class_name Glow

@export var AMPLITUDE = 0.2
@export var BASELINE = 0.1
@export var FREQUENCY = 1/500.0

func _process(_delta: float) -> void:
	self_modulate.a = abs( 
		AMPLITUDE * sin( 
			Time.get_ticks_msec() 
			* FREQUENCY 
			)
		) + BASELINE
