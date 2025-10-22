extends PlantAction
class_name ConnectAction

func get_cost(plant: PlantData) -> PlantActionCost:
	var cost = PlantActionCost.new()
	if plant != null:
		cost.requirements = {'energy': plant.get_connect_cost()}
	return cost

func is_visible(_plant: PlantData) -> bool:
	return true

func meets_action_requirements(plant: PlantData) -> bool:
	return not plant.is_in_network if plant else false

func execute(plant: PlantData) -> PlantActionResult:
	var cost = get_cost(plant)
	if not cost.can_pay():
		return PlantActionResult.fail("Not enough resources")
	cost.pay()
	plant.connect_to_network()
	return PlantActionResult.success()
