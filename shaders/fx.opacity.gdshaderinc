group_uniforms Opacity;
/** Overall material opacity (0 = invisible, 1 = full opacity) */
uniform float opacity : hint_range(0.0, 1.0) = 1.0;
/** Wave effects opacity (0 = original texture only, 1 = full effects) */
uniform float effect_opacity : hint_range(0.0, 1.0) = 1.0;
/** Use brightness as transparency (darker = transparent, lighter = opaque) */
uniform bool brightness_as_alpha = false;
/** Brightness threshold for transparency (higher = more areas become transparent) */
uniform float alpha_threshold : hint_range(0.0, 2.0) = 1.0;
/** Enable radial opacity falloff from center */
uniform bool enable_radial_opacity = false;
/** Center enter for radial opacity */
uniform vec2 radial_opacity_center = vec2(0.5, 0.5);
/** Radius for opaque area */
uniform float opaque_radius : hint_range(0.0, 2.0) = 0.5;
/** Ring thickness - creates transparent area inside opaque radius */
uniform float ring_thickness : hint_range(0.0, 1.0) = 0.4;
/** Speed of opacity falloff (1.0 = linear, higher = sharper) */
uniform float radial_opacity_falloff : hint_range(0.1, 20.0) = 1.0;
/** Invert radial opacity (true = opaque at edges, transparent at center) */
uniform bool invert_radial_opacity = false;

Ctx stage_opacity(Ctx c) {

    c.alpha = effect_opacity;

	// Apply radial opacity if enabled
	float final_opacity = opacity;
	if (enable_radial_opacity) {
		// Apply the same X/Y scaling used for radial waves to the opacity calculation
		vec2 scaled_opacity_position = c.uv - texture_center;
		float scaled_radial_value_x = radial_scale.x / c.uv_scale;
		float scaled_radial_value_y = radial_scale.y / c.uv_scale;
		scaled_opacity_position.x /= scaled_radial_value_x;
		scaled_opacity_position.y /= scaled_radial_value_y;
		float distance_from_center = length(scaled_opacity_position);

		// Scale the radii to match the coordinate space transformation
		float scaled_outer_radius = opaque_radius / max(scaled_radial_value_x, scaled_radial_value_y);
		float scaled_inner_radius = max(0.0, (opaque_radius - ring_thickness)) / max(scaled_radial_value_x, scaled_radial_value_y);

		// Create ring: transparent inside inner radius, opaque between inner and outer, transparent beyond outer
		float radial_alpha;

		if (ring_thickness <= 0.0) {
			// When ring thickness is 0, everything should be transparent
			radial_alpha = 0.0;
		} else {
			// Fade from transparent at center to opaque at inner radius
			float inner_fade = smoothstep(scaled_inner_radius - 0.05, scaled_inner_radius + 0.05, distance_from_center);
			// Fade from opaque at outer radius to transparent beyond
			float outer_fade = 1.0 - smoothstep(scaled_outer_radius - 0.05, scaled_outer_radius + 0.05, distance_from_center);

			radial_alpha = inner_fade * outer_fade;
		}
		radial_alpha = pow(radial_alpha, radial_opacity_falloff);

		if (invert_radial_opacity) {
			radial_alpha = 1.0 - radial_alpha; // Invert the entire effect
		}

		final_opacity *= radial_alpha;
	}

	// Apply brightness-as-alpha if enabled
	if (brightness_as_alpha) {
		// Use wave value directly for consistent radial pattern
		float wave_value = c.w1 + c.w2 + c.pulse_wave;
		// Normalize wave from [-1,1] to [0,1]
		float normalized_wave = (wave_value + 1.0) * 0.5;

		// Apply threshold - higher threshold makes more areas opaque
		float brightness_alpha = clamp((normalized_wave - (1.0 - alpha_threshold)) / alpha_threshold, 0.0, 1.0);
		final_opacity *= brightness_alpha;
	}

	// Apply overall opacity to alpha channel for transparency overlay effect
	c.alpha = c.alpha * final_opacity;

    return c;
}