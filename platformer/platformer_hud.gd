extends Control

@onready var timer: Timer = $"../../Timer"

# During Gameplay
@onready var time_label = $Time
@onready var height_label = $Score
@onready var high_score: RichTextLabel = $HighScore

#After Gameplay Stats
@onready var post_run_message: RichTextLabel = $PostRunMessage
@onready var energy_gained: RichTextLabel = $EnergyGained

var last_second = 0
var base_scale = Vector2(0.8, 0.8)  # Start at 80% size

func update(y):
	if timer.is_stopped():
		animate_final_blink()
	update_timer_appearance()
	height_label.text = "Score: \n%.1fm" % Global.convert_pixel_height_to_meters(y)

func update_timer_appearance():
	var minutes = timer.time_left / 60
	var seconds = int(timer.time_left) % 60
	time_label.text = "%02d:%02d" % [minutes, seconds]
	
	var current_second = int(timer.time_left)
	
	# Handle per-second effects in last 5 seconds
	if timer.time_left <= 5.0 and current_second != last_second:
		if current_second < 5:
			animate_second_pop()
	last_second = current_second
	
	if timer.time_left > 15:
		time_label.modulate = Color.WHITE
	elif timer.time_left > 10:
		time_label.modulate = Color.GREEN
	elif timer.time_left > 5:
		time_label.modulate = Color.YELLOW
	else:
		time_label.modulate = Color.RED

func animate_second_pop():
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Pop to 110% and flash white
	tween.tween_property(time_label, "scale", Vector2(1.1, 1.1), 0.1)
	tween.tween_property(time_label, "modulate", Color.WHITE, 0.1)
	
	# Shrink to 90% and back to red
	tween.tween_property(time_label, "scale", Vector2(0.9, 0.9), 0.3).set_delay(0.1)
	tween.tween_property(time_label, "modulate", Color.RED, 0.3).set_delay(0.1)

func animate_final_blink():
	var tween = create_tween()
	tween.set_loops(3)
	tween.tween_property(time_label, "modulate", Color.WHITE, 0.2)
	tween.tween_property(time_label, "modulate", Color.RED, 0.2)
	
	# Final state at 100% white
	tween.tween_callback(func(): 
		time_label.modulate = Color.WHITE
		time_label.scale = Vector2(1.0, 1.0)
	).set_delay(1.2)

func update_record_height(y):
	high_score.text = "Record: \n%.1fm" % y
	
func show_run_stats(energy_amount):
	energy_gained.text = "Energy Gained: \n" + str(energy_amount)
	time_label.hide()
	height_label.hide()
	high_score.hide()
	if timer.time_left == 0:
		post_run_message.text = "Time's Up!"
	else:
		post_run_message.text = "Plant Cleared!"
	post_run_message.show()
	energy_gained.show()
	
