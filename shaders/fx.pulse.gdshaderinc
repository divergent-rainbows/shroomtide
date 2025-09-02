group_uniforms PulseMode;
/** Speed of pulse animation as a multiplier of wave speed */
uniform float pulse_speed : hint_range(0.1, 1.0) = 0.1;
/** Strength of pulse effect */
uniform float pulse_intensity : hint_range(0.1, 1.0) = 0.5;

Ctx stage_pulse_effect(Ctx c){
	// Add pulse mode if enabled
	if (enable_pulse_mode) {
		float pulse_time = c.t * pulse_speed;
		c.pulse_wave = sin(pulse_time) * pulse_intensity;
	}
    return c;
}