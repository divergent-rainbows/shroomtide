extends AnimatedSprite2D
class_name GrassBlade

func _ready() -> void:
	## randomly skew
	skew = randf_range(-5.0, 5.0)
