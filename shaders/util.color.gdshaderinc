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

group_uniforms RainbowWaves;
/** Enable rainbow color cycling on waves */
uniform bool rainbow_mode = false;
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
	float brightness = 1.0 + brightness_bias + enhanced_wave * brightness_amount;

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
		float hue =	fract(
			a01 * radial_cycles + 
			distance_from_center * spiral_strength + 
			phase);

		vec3 rainbow_color = hsv_to_rgb(vec3(hue, rainbow_saturation, 1.0));

		// Apply rainbow based on wave intensity
		float wave_intensity = abs(c.w1 + c.w2 + c.pulse_wave);
		vec3 rainbow_color_mod = mix(vec3(1.0), rainbow_color, wave_intensity * rainbow_strength);
		c.color *= rainbow_color_mod; 
	}
	return c;
}
