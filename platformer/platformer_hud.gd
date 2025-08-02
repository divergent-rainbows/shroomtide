extends Control

const TIMEOUT = "Time's up!"
const RUN_SUCCESS = "Plant cleared!"
const LEFT_LABEL = "Score"
const RIGHT_LABEL = "Record"

@onready var platformer_level: Node2D = $"../.."
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
	update_timer_appearance()
	height_label.text = "%s: \n%.1fm" % \
		[LEFT_LABEL, Global.convert_pixel_height_to_meters(y)]

func update_timer_appearance():
	var minutes = timer.time_left / 60
	var seconds = int(timer.time_left) % 60
	time_label.text = "%02d:%02d" % [minutes, seconds]
		
	if timer.time_left > 15:
		time_label.modulate = Color.WHITE
	elif timer.time_left > 10:
		time_label.modulate = Color.GREEN
	elif timer.time_left > 5:
		time_label.modulate = Color.YELLOW
	else:
		time_label.modulate = Color.RED

func update_record_height(y):
	high_score.text = "%s: \n%.1fm" % [RIGHT_LABEL, y]
	
func show_run_stats():
	time_label.hide()
	height_label.hide()
	high_score.hide()
	if timer.time_left == 0:
		post_run_message.text =  TIMEOUT
	else:
		post_run_message.text = RUN_SUCCESS
	post_run_message.show()
	energy_gained.show()
	platformer_level.stats_shown = true
	
