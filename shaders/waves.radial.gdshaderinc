group_uniforms RadialWaves;
/** Distance between wave peaks (lower = wider waves) */
uniform float radial_frequency : hint_range(1.0, 50.0) = 5.0;
/** Direction of radial waves (-1.0 = inward, 1.0 = outward) */
uniform int radial_direction : hint_enum("Inward", "Outward") = 0;
/** Radial wave scale (lower = smaller waves, higher = larger waves) */
uniform vec2 radial_scale = vec2(1.0,1.0);
/** Lock Y scale to X scale for perfect circles */
uniform bool lock_aspect_ratio = false;
/** Auto-correct aspect ratio for perfect circles (requires aspect_ratio uniform) */
uniform bool auto_aspect_correction = false;
/** Material aspect ratio (width/height) - set from script for auto correction */
uniform float aspect_ratio : hint_range(0.1, 5.0) = 1.0;
/** Wave sharpness (1.0 = normal, higher = thinner highlighted areas) */
uniform float wave_sharpness : hint_range(0.1, 3.0) = 1.0;
/** Wave threshold bias (negative = shrink lights, positive = expand lights) */
uniform float radial_wave_bias : hint_range(-1.0, 1.0) = 0.0;


group_uniforms RadialDynamics;
/** Enable wave direction oscillation */
uniform bool enable_oscillation = false;
/** Controls the degree of movement within each cycle */
uniform float oscillation_magnitude : hint_range(1.0, 50.0) = 3.0;
/** Oscillation bounce intensity (1 = small bounce, higher = larger bounces) */
uniform float oscillation_speed : hint_range(0.1, 5.0) = 1.0;
/** Space between changes in cycle */
uniform float cycle_gap : hint_range(0.0, 1.0) = 0.5;

#include "res://shaders/fx.radial_acceleration.gdshaderinc"

Ctx stage_radial_effects(Ctx c){
    // Apply separate X/Y scaling to create non-uniform radial waves
    vec2  position = c.uv - texture_center;

    // Apply scaling with optional aspect ratio correction
    vec2 effective_scale = radial_scale;
    if (lock_aspect_ratio) {
        effective_scale.y = effective_scale.x;
    } else if (auto_aspect_correction) {
        // Adjust Y scale based on aspect ratio to maintain perfect circles
        effective_scale.y = effective_scale.x * aspect_ratio;
    }

    position /= effective_scale;
    float distance = length(position);
    float radial_magnitude =  c.speed * c.t;

    if (enable_oscillation) {
        float phase = sin(c.t * oscillation_speed);
        float dir = smoothstep(0.0, 1.0 - cycle_gap, abs(phase)) * sign(phase);
        radial_magnitude = dir * oscillation_magnitude * PI;
    }

    // sets distance_based_frequency
    c = stage_radial_acceleration(c);

    float raw_wave = sin(
        distance * radial_frequency * PI
        + radial_magnitude
        * (radial_direction == 0 ? 1.0 : -1.0));

    // Apply wave sharpness
    if (wave_sharpness == 1.0) {
        // Smooth gradient: create triangle wave for continuous smooth transitions
        float phase = fract(distance * radial_frequency);

        // Apply wave bias to skew the triangle wave
        float bias_point = clamp(0.5 + radial_wave_bias * 0.4, 0.1, 0.9);

        // Create asymmetric triangle wave
        float gradient = mix(
            (phase / bias_point) * 2.0 - 1.0,
            1.0 - ((phase - bias_point) / (1.0 - bias_point)) * 2.0,
            step(bias_point, phase)
        );

        c.w1 = gradient;
    } else if (wave_sharpness < 1.0) {
        // Smooth transitions: reduce contrast
        c.w1 = raw_wave * wave_sharpness;
    } else {
        // Sharp transitions: increase contrast using power function
        c.w1 = sign(raw_wave) * pow(abs(raw_wave), wave_sharpness);
    }
    return c;
}