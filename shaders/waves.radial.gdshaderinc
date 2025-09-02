group_uniforms RadialWaves;
/** Distance between wave peaks (lower = wider waves) */
uniform float radial_frequency : hint_range(1.0, 50.0) = 5.0;
/** Direction of radial waves (-1.0 = inward, 1.0 = outward) */
uniform int radial_direction : hint_enum("Inward", "Outward") = 0;
/** Radial wave scale (lower = smaller waves, higher = larger waves) */
uniform vec2 radial_scale = vec2(1.0,1.0);
/** Wave sharpness (1.0 = normal, higher = thinner highlighted areas) */
uniform float wave_sharpness : hint_range(0.1, 3.0) = 1.0;


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
    c.w1 = pow(abs(raw_wave), wave_sharpness) * sign(raw_wave);
    return c;
}