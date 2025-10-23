extends GridContainer
class_name InspectorStats

const HEALTH_COLORS = {
	Global.HealthStatus.Thriving: Color.GREEN,
	Global.HealthStatus.Recovered: Color.GREEN_YELLOW,
	Global.HealthStatus.Healing: Color.YELLOW,
	Global.HealthStatus.Dead: Color.RED,
	Global.HealthStatus.Unknown: Color.WHITE
}

@onready var health_bar: ProgressBar = $HealthBar
@onready var leaf_label: Label = $LeafLabel
@onready var energy_label: Label = $EnergyLabel
@onready var nurture_label: Label = $NurtureLabel
var _is_rebuilding = false

func _rebuild(plant: PlantData) -> void:
	if plant == null: 
		return 
	_is_rebuilding = true
	health_bar.indeterminate = not plant.is_in_network
	health_bar.modulate = HEALTH_COLORS[plant.get_health_status()]
	health_bar.value = plant.get_health_percent() * 100
	leaf_label.text = "%s / %s" % [plant.get_leaf_count(), plant.max_num_leaves]
	energy_label.text = "+ %s/s" % plant.get_glycosine_per_tick()
	nurture_label.text = "+ %s" % plant.get_nurture_reward()
	await get_tree().create_timer(0.1).timeout
	_is_rebuilding = false
