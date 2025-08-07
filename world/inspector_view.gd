extends Control

@onready var label: Label = $Label
@onready var timer: Timer = $Timer

func show_inspection(text, stall = 2.0):
	label.text = text
	
	# Position message on opposite side of screen from player position
	_position_message_opposite_to_player()
	
	label.show()
	timer.start(stall)

func _position_message_opposite_to_player():
	# Get player's actual screen position directly from the shroomie node
	var shroomie = get_node("../../Shroomie")
	var player_screen_pos = shroomie.global_position
	
	var screen_height = get_viewport().get_visible_rect().size.y
	var screen_center_y = screen_height / 2
	
	# If player is in top half, show message in bottom half and vice versa
	if player_screen_pos.y < screen_center_y:
		# Player is in top half, show message in bottom half
		position.y = screen_height * 0.75  # 75% down the screen
	else:
		# Player is in bottom half, show message in top half  
		position.y = screen_height * 0.25  # 25% down the screen

func _on_timer_timeout() -> void:
	label.hide()
