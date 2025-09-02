group_uniforms NoiseDistortion;
/** Enable noise effect */
uniform bool  enable_noise = false;
/** Size of noise patterns (lower = larger features) */
uniform float noise_scale : hint_range(1.0, 50.0) = 10.0;
/** Intensity of noise distortion */
uniform float noise_strength : hint_range(0.0, 0.2) = 0.05;
/** Speed of noise animation */
uniform float noise_speed : hint_range(1.0, 500.0) = 100.0;
/** Horizontal noise drift direction */
uniform float noise_direction_x : hint_range(-2.0, 2.0) = 0.5;
/** Vertical noise drift direction */
uniform float noise_direction_y : hint_range(-2.0, 2.0) = 0.0;
/** Creates directional wave asymmetry */
uniform float asymmetry_strength : hint_range(0.0, 1.0) = 0.0;
/** Direction of asymmetric effects (radians) */
uniform float asymmetry_angle : hint_range(0.0, 6.28) = 0.0;

// Simple noise function for distortion effects
float noise(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// Smooth noise with interpolation
float smooth_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f); // Smooth interpolation

	float a = noise(i);
	float b = noise(i + vec2(1.0, 0.0));
	float c = noise(i + vec2(0.0, 1.0));
	float d = noise(i + vec2(1.0, 1.0));

	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

Ctx stage_noise(Ctx c){
    // Apply noise distortion if enabled
	if (enable_noise) {
		float noise_time = (TIME + time_offset) * (noise_speed / 1000.0);
		vec2 noise_drift = vec2(noise_direction_x, noise_direction_y) * noise_time;

		// Generate noise at multiple scales for natural look
		float noise1 = smooth_noise((c.uv + noise_drift) * noise_scale);
		float noise2 = smooth_noise((c.uv + noise_drift) * noise_scale * 2.0) * 0.5;
		float combined_noise = (noise1 + noise2 - 0.75) * noise_strength;

		// Apply asymmetric distortion
		vec2 asymmetry_dir = vec2(cos(asymmetry_angle), sin(asymmetry_angle));
		float asymmetry_factor = dot(c.uv - vec2(0.5), asymmetry_dir) * asymmetry_strength;

		c.uv += vec2(combined_noise + asymmetry_factor * 0.1, combined_noise * 0.7);
	}
    return c;
}