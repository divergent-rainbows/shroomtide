group_uniforms Brightness;
/** Overall wave effect intensity */
uniform float brightness_amount : hint_range(0.0, 1.0) = 0.5;
/** Color saturation enhancement */
uniform float saturation_boost : hint_range(-0.3, 0.3) = 0.0;
/** Wave contrast enhancement (1.0 = normal, higher = more contrast) */
uniform float contrast : hint_range(0.1, 5.0) = 1.0;
/** Wave threshold bias (negative = shrink lights, positive = expand lights) */
uniform float wave_bias : hint_range(-1.0, 1.0) = 0.0;
/** Color tint for wave effects */
uniform vec4 wave_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
/** Strength of wave color tinting (0 = no tint, 1 = full color) */
uniform float wave_color_strength : hint_range(0.0, 1.0) = 0.0;
/** Minimum brightness level (darkest the shader can get) */
uniform float brightness_min : hint_range(0.0, 1.0) = 0.0;
/** Maximum brightness level (brightest the shader can get) */
uniform float brightness_max : hint_range(0.0, 2.0) = 1.0;
/** Normalize brightness to min/max range (true) or clamp to min/max (false) */
uniform bool brightness_normalize = false;

group_uniforms RainbowWaves;
/** Enable rainbow color cycling on waves */
uniform bool rainbow_mode = false;
/** Type of rainbow pattern */
uniform int rainbow_type : hint_enum("Classic", "Pastel", "Vibrant", "Neon", "Triads", "Complementary", "Analogous", "Tetradic") = 0;
/** Strength of spiral */
uniform float spiral_strength : hint_range(-10.0, 10.0) = 0.0;
/** Number of full rainbow cycles of rainbow colors */
uniform float radial_cycles : hint_range(0.0, 10.0, 1.0) = 1.0;
/** Speed of rainbow color cycling */
uniform float rainbow_speed : hint_range(0.0, 5.0) = 0.1;
/** Intensity of rainbow colors */
uniform float rainbow_saturation : hint_range(0.0, 1.0) = 0.8;
/** Overall rainbow effect intensity */
uniform float rainbow_strength : hint_range(0.0, 1.0) = 0.5;
/** Base color for color theory rainbows (primary color) */
uniform vec4 color_theory_base : source_color = vec4(1.0, 0.0, 0.0, 1.0);
/** Smooth transitions between colors (true) or hard bands (false) */
uniform bool color_theory_smooth = true;

// Rainbow type constants
const int RAINBOW_CLASSIC = 0;
const int RAINBOW_PASTEL = 1;
const int RAINBOW_VIBRANT = 2;
const int RAINBOW_NEON = 3;
const int RAINBOW_TRIADS = 4;
const int RAINBOW_COMPLEMENTARY = 5;
const int RAINBOW_ANALOGOUS = 6;
const int RAINBOW_TETRADIC = 7;

vec3 rgb_to_hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv_to_rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

Ctx stage_brightness_bias(Ctx c) {
	float combined_wave = c.w1 + c.w2 + c.pulse_wave;

	// Apply wave bias (shifts the light/dark threshold)
	float biased_wave = combined_wave + wave_bias;

	// Apply contrast enhancement to waves
	float enhanced_wave = biased_wave;

	// Center the wave around 0, apply contrast, then restore
	enhanced_wave = (biased_wave * contrast);
	enhanced_wave = clamp(enhanced_wave, -2.0, 2.0); // Prevent extreme values

	// Apply brightness modulation
	float raw_brightness = 0.5 + brightness_bias + enhanced_wave * brightness_amount;
	// Apply brightness range control
	float brightness;
	if (brightness_normalize) {
		// Normalize: remap [0,1] to [brightness_min, brightness_max]
		brightness = mix(brightness_min, brightness_max, raw_brightness);
	} else {
		// Clamp: keep original value but constrain to min/max bounds
		brightness = clamp(raw_brightness, brightness_min, brightness_max);
	}

	// Apply saturation boost to base color
	vec3 saturated_base;
	vec3 hsv = rgb_to_hsv(c.base_pixel.rgb);
	hsv.y = clamp(hsv.y + saturation_boost, 0.0, 1.0);
	saturated_base = hsv_to_rgb(hsv) * brightness;

	float wave_intensity = clamp(enhanced_wave * brightness_amount + 0.5, 0.0, 1.0);

	// Apply tint with base color with wave color based on wave intensity and strength
	c.color = mix(saturated_base, wave_color.rgb, wave_intensity * wave_color_strength);


	return c;
}

Ctx stage_rainbow_modulation(Ctx c){
	if (rainbow_mode) {
		vec2 rainbow_pos = c.uv - texture_center;
		float distance_from_center = length(rainbow_pos);
		float angle = atan(rainbow_pos.y, rainbow_pos.x);
		float a01 =  (angle + PI) / TAU; // -> [0,1)

		// Create rainbow pattern based on waves and position
		float phase = c.t * (rainbow_speed);
		float hue_base = a01 * radial_cycles + distance_from_center * spiral_strength + phase;
		float hue = mod(hue_base + sin(hue_base * TAU) * 0.1, 1.0);

		// Get the current brightness from the existing color
		vec3 current_hsv = rgb_to_hsv(c.color);
		float current_brightness = current_hsv.z;

		// Create rainbow color based on type
		vec3 rainbow_color;
		switch (rainbow_type) {
			case RAINBOW_PASTEL:
				rainbow_color = hsv_to_rgb(vec3(hue, rainbow_saturation * 0.6, min(current_brightness + 0.3, 1.0)));
				break;
			case RAINBOW_VIBRANT:
				rainbow_color = hsv_to_rgb(vec3(hue, min(rainbow_saturation * 1.2, 1.0), current_brightness));
				break;
			case RAINBOW_NEON:
				rainbow_color = hsv_to_rgb(vec3(hue, 1.0, min(current_brightness + 0.2, 1.0)));
				break;
			case RAINBOW_TRIADS:
			case RAINBOW_COMPLEMENTARY:
			case RAINBOW_ANALOGOUS:
			case RAINBOW_TETRADIC:
				// Get base color hue for color theory calculations
				vec3 base_hsv = rgb_to_hsv(color_theory_base.rgb);
				float base_hue = base_hsv.x;

				// Define color scheme hues based on type
				float color_hues[4];
				int num_colors;

				if (rainbow_type == RAINBOW_TRIADS) {
					// Triadic: 120° apart
					color_hues[0] = base_hue;
					color_hues[1] = mod(base_hue + 0.333, 1.0);
					color_hues[2] = mod(base_hue + 0.667, 1.0);
					num_colors = 3;
				} else if (rainbow_type == RAINBOW_COMPLEMENTARY) {
					// Complementary: 180° apart
					color_hues[0] = base_hue;
					color_hues[1] = mod(base_hue + 0.5, 1.0);
					num_colors = 2;
				} else if (rainbow_type == RAINBOW_ANALOGOUS) {
					// Analogous: base + adjacent colors (30° each side)
					color_hues[0] = mod(base_hue - 0.083, 1.0);
					color_hues[1] = base_hue;
					color_hues[2] = mod(base_hue + 0.083, 1.0);
					num_colors = 3;
				} else { // RAINBOW_TETRADIC
					// Tetradic: square (90° apart)
					color_hues[0] = base_hue;
					color_hues[1] = mod(base_hue + 0.25, 1.0);
					color_hues[2] = mod(base_hue + 0.5, 1.0);
					color_hues[3] = mod(base_hue + 0.75, 1.0);
					num_colors = 4;
				}

				if (color_theory_smooth) {
					// Find closest color and interpolate
					float min_dist = 1.0;
					float second_min_dist = 1.0;
					int closest_idx = 0;
					int second_closest_idx = 1;

					for (int i = 0; i < num_colors; i++) {
						float dist = min(abs(hue - color_hues[i]), 1.0 - abs(hue - color_hues[i]));
						if (dist < min_dist) {
							second_min_dist = min_dist;
							second_closest_idx = closest_idx;
							min_dist = dist;
							closest_idx = i;
						} else if (dist < second_min_dist) {
							second_min_dist = dist;
							second_closest_idx = i;
						}
					}

					// Interpolate between two closest colors
					float t = min_dist / (min_dist + second_min_dist);
					float interpolated_hue = mix(color_hues[closest_idx], color_hues[second_closest_idx], t);
					rainbow_color = hsv_to_rgb(vec3(interpolated_hue, rainbow_saturation, current_brightness));
				} else {
					// Hard bands - snap to closest color
					float min_dist = 1.0;
					int closest_idx = 0;

					for (int i = 0; i < num_colors; i++) {
						float dist = min(abs(hue - color_hues[i]), 1.0 - abs(hue - color_hues[i]));
						if (dist < min_dist) {
							min_dist = dist;
							closest_idx = i;
						}
					}

					rainbow_color = hsv_to_rgb(vec3(color_hues[closest_idx], rainbow_saturation, current_brightness));
				}
				break;
			case RAINBOW_CLASSIC:
			default:
				rainbow_color = hsv_to_rgb(vec3(hue, rainbow_saturation, current_brightness));
				break;
		}

		// Apply rainbow based on rainbow strength
		c.color = mix(c.color, rainbow_color, rainbow_strength); 
	}
	return c;
}
