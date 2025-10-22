extends PlantAction
class_name NurtureAction

func get_cost(plant: PlantData) -> PlantActionCost:
	var cost = PlantActionCost.new()
	cost.requirements['energy'] = plant.get_nurture_cost()
	return cost

func is_visible(_plant: PlantData) -> bool:
	return true

func meets_action_requirements(plant: PlantData) -> bool:
	return plant.is_in_network and plant.is_revived

func execute(plant: PlantData) -> PlantActionResult:
	var cost = get_cost(plant)
	if not cost.can_pay():
		return PlantActionResult.fail("Not enough resources")
	cost.pay()
	Global.control_override = false
	Global.goto_scene(Global.PLATFORMER_SCENE_PATH, plant)
	return PlantActionResult.success()
