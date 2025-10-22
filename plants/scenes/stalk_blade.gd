extends AnimatedSprite2D

@export var side : bool
@export var stage : int

@onready var glow : Sprite2D = $Glow

func _process(_delta: float) -> void:
	if flip_h:
		glow.flip_h = true
