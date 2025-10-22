extends PlantAction
class_name ReviveAction

func get_cost(plant: PlantData) -> PlantActionCost:
	var cost = PlantActionCost.new()
	cost.requirements = {'energy': plant.get_revive_cost()}
	return cost

func is_visible(_plant: PlantData) -> bool:
	return true

func meets_action_requirements(plant: PlantData) -> bool:
	return plant.is_in_network and not plant.is_revived

func execute(plant: PlantData) -> PlantActionResult:
	var cost = get_cost(plant)
	if not cost.can_pay():
		return PlantActionResult.fail("Not enough resources")
	cost.pay()
	plant.revive()
	return PlantActionResult.success()
