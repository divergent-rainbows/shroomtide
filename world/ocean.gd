extends TileMapLayer

@export var fade_in_duration: float = 10.0
@export var opacity_parameter_name: String = "effect_opacity"

var _shader_material: ShaderMaterial
var _is_initialized: bool = false

func _ready() -> void:
	# Ensure proper initialization
	call_deferred("_initialize_ocean_shader")

func _initialize_ocean_shader() -> void:
	# Wait for scene to be fully loaded
	await get_tree().process_frame

	# Validate tilemap layer is properly set up
	if not _validate_tilemap_setup():
		print("Warning: Ocean tilemap not properly configured")
		return

	# Get or create shader material
	if not _ensure_shader_material():
		print("Error: Could not initialize ocean shader material")
		return

	# Start with shader effect disabled
	_set_effect_opacity(0.0)

	# Wait one more frame to ensure everything is ready
	await get_tree().process_frame

	# Tween the shader effect in
	_tween_shader_effect_in()
	_is_initialized = true

func _validate_tilemap_setup() -> bool:
	# Check if tilemap has tiles
	if get_used_cells().size() == 0:
		print("Warning: Ocean tilemap has no tiles")
		return false

	# Check if tilemap is visible
	if not visible:
		print("Warning: Ocean tilemap is not visible")
		return false

	return true

func _ensure_shader_material() -> bool:
	# Check if material exists
	if not material:
		print("Warning: No material assigned to ocean tilemap")
		return false

	# Ensure it's a shader material
	if not material is ShaderMaterial:
		print("Warning: Ocean material is not a ShaderMaterial")
		return false

	_shader_material = material as ShaderMaterial

	# Check if shader is loaded
	if not _shader_material.shader:
		print("Warning: Shader not loaded in material")
		return false

	return true

func _set_effect_opacity(opacity: float) -> void:
	if _shader_material and _shader_material.shader:
		_shader_material.set_shader_parameter(opacity_parameter_name, opacity)

func _tween_shader_effect_in() -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)

	# Tween from 0 to 1 over the specified duration
	tween.tween_method(_set_effect_opacity, 0.0, 1.0, fade_in_duration)

	await tween.finished
	print("Ocean shader effect fade-in complete")

# Public method to force reinitialize if needed
func reinitialize_shader() -> void:
	if _is_initialized:
		_set_effect_opacity(0.0)
		await get_tree().process_frame
		_initialize_ocean_shader()

# Debug method to check shader state
func get_shader_debug_info() -> Dictionary:
	return {
		"has_material": material != null,
		"is_shader_material": material is ShaderMaterial,
		"has_shader": _shader_material != null and _shader_material.shader != null,
		"is_initialized": _is_initialized,
		"current_opacity": _shader_material.get_shader_parameter(opacity_parameter_name) if _shader_material else 0.0,
		"tile_count": get_used_cells().size(),
		"is_visible": visible
	}
