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
/** Inner radius for opacity transition start */
uniform float inner_radial_opacity_radius : hint_range(0.0, 2.0) = 0.3;
/** Outer radius for opacity transition end */
uniform float outer_radial_opacity_radius : hint_range(0.1, 2.0) = 0.7;
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
		vec2 scaled_opacity_position = c.uv - radial_opacity_center;
		float scaled_radial_value_x = radial_scale.x / c.uv_scale;
		float scaled_radial_value_y = radial_scale.y / c.uv_scale;
		scaled_opacity_position.x /= scaled_radial_value_x;
		scaled_opacity_position.y /= scaled_radial_value_y;
		float distance_from_center = length(scaled_opacity_position);

		// Scale the radii to match the coordinate space transformation
		float scaled_inner_radius = inner_radial_opacity_radius / max(scaled_radial_value_x, scaled_radial_value_y);
		float scaled_outer_radius = outer_radial_opacity_radius / max(scaled_radial_value_x, scaled_radial_value_y);

		// Calculate radial opacity using two smooth transitions that meet in the middle
		// Inner transition: fade from center (transparent) to inner radius (opaque)
		float inner_progress = smoothstep(0.0, scaled_inner_radius, distance_from_center);
		inner_progress = pow(inner_progress, radial_opacity_falloff);

		// Outer transition: fade from outer radius (opaque) to beyond (transparent)
		float outer_progress = 1.0 - smoothstep(scaled_outer_radius, scaled_outer_radius * 1.5, distance_from_center);
		outer_progress = pow(outer_progress, radial_opacity_falloff);

		// Combine both transitions - take minimum to create island mask with ocean fade
		float radial_alpha = min(inner_progress, outer_progress);

		if (invert_radial_opacity) {
			radial_alpha = 1.0 - radial_alpha; // Invert the entire effect
		}

		final_opacity *= radial_alpha;
	}

	// Apply brightness-as-alpha if enabled
	if (brightness_as_alpha) {
		// Calculate brightness of final color
		float color_brightness = dot(c.color, vec3(0.299, 0.587, 0.114)); // Luma RGB coefficients

		// Convert brightness to alpha (darker = transparent, lighter = opaque)
		float brightness_alpha = clamp(color_brightness / alpha_threshold, 0.0, 1.0);
		final_opacity *= brightness_alpha;
	}

	// Apply overall opacity to alpha channel for transparency overlay effect
	c.alpha = c.alpha * final_opacity;

    return c;
}