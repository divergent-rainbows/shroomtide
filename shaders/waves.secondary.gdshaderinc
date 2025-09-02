group_uniforms SecondaryWaves;
/** Enable receding tide effect */
uniform bool enable_secondary_wave = false;
/** Wave pattern type (0=Linear, 1=Radial) */
uniform int secondary_waveform : hint_enum("Linear", "Radial") = 0;
/** Secondary wave size (lower = smaller waves, higher = larger waves) */
uniform vec2 secondary_wave_scale = vec2(5.0, 5.0);
/** Secondary wave movement direction and magnitude */
uniform vec2 secondary_wave_direction = vec2(0.0, 0.0);
/** Speed of wave animation */
uniform float secondary_wave_speed : hint_range(0.0, 100.0) = 10.0;
/** Intensity of secondary wave effect */
uniform float secondary_wave_strength : hint_range(0.0, 1.0) = 0.3;
/** Speed of tidal cycle switching */
uniform float cycle_speed : hint_range(0.00, 10.0) = 0.0;
/** Phase offset between primary and secondary waves */
uniform float cycle_magnitude : hint_range(0.0, 10.0) = 0;

Ctx stage_secondary_waves(Ctx c) {
    // Create secondary wave layer if enabled
	if (enable_secondary_wave) {
		float time2 = c.t * secondary_wave_speed;

        switch (secondary_waveform) {
            case WAVE_RADIAL:
                vec2  position = c.uv - texture_center;
                float distance = length(position);
                float frequency = radial_frequency * secondary_wave_scale.x;

                float phase = sin(time2 * cycle_speed);

                float dead_zone   = 0.5;
                float dir = smoothstep(0.0, dead_zone, abs(phase)) * sign(phase);

                c.w2 = sin( distance * frequency + dir * cycle_magnitude ) * secondary_wave_strength;
                break;
            case WAVE_LINEAR:
            default:
                c.w2 = sin(
                        c.uv.x /  (secondary_wave_scale.x / c.uv_scale) + 
                        c.t * secondary_wave_speed * secondary_wave_direction.x
                    ) + cos(
                        c.uv.y /  (secondary_wave_scale.y / c.uv_scale) + 
                        c.t * secondary_wave_speed * secondary_wave_direction.y
                    );
                c.w2 = c.w2 * secondary_wave_strength;
                break;
        }
	}

    return c;
}