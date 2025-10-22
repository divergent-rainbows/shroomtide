extends Resource
class_name PlantActionResult

@export var ok := false
@export var reason := ""

static func success() -> PlantActionResult:
	var r := PlantActionResult.new() 
	r.ok = true
	return r

static func fail(msg: String) -> PlantActionResult:
	var r := PlantActionResult.new()
	r.ok = false
	r.reason = msg
	return r
