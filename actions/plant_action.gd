extends Resource
class_name PlantAction

@export var id: String
@export var label: String
@export var priority: int = 0

func get_cost(_plant) -> PlantActionCost:
	push_warning("ActionCost '%s' not implemented." % id)
	return PlantActionCost.new()


func is_visible(_plant) -> bool:
	return true


func can_execute(_plant) -> bool:
	return meets_action_requirements(_plant) and can_pay(_plant)


func meets_action_requirements(_plant) -> bool:
	return true
	
	
func can_pay(_plant) -> bool:
	return get_cost(_plant).can_pay()


func execute(_plant) -> PlantActionResult:
	push_warning("Action '%s' has no implementation." % id)
	return PlantActionResult.success()
