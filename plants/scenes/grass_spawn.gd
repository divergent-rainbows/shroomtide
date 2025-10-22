extends Node2D
class_name GrassSpawn

func _ready() -> void:
	## randomly flip_h
	scale.x = 1 if randi() % 2 == 0 else -1 
