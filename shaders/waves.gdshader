shader_type canvas_item;

/** Enable/disable all shader effects */
uniform bool enable = true;
/** Wave pattern type (0=Linear, 1=Radial) */
uniform int primary_waveform : hint_enum("Linear", "Radial") = 0;
/** Enable additional pulsing effect */
uniform bool enable_pulse_mode = false;
/** Center of the texture (x,y) for wave origin */
uniform vec2 texture_center = vec2(0.5, 0.5);
/** Horizontal wave pattern offset */
uniform vec2 wave_offset = vec2(0.0, 0.0);
/** Time offset for synchronizing effects across layers */
uniform float time_offset : hint_range(0.0, 10.0) = 0.0;
/** Define normalized units across texture **/
uniform float uv_scale : hint_range(10.0, 2000.0) = 1000.0;
/** Base brightness adjustment */
uniform float brightness_bias : hint_range(-1.0, 1.0) = 0.0;

#include "res://shaders/waves.constants.gdshaderinc"
#include "res://shaders/waves.linear.gdshaderinc"
#include "res://shaders/fx.pixelate.gdshaderinc"
#include "res://shaders/fx.noise.gdshaderinc"
#include "res://shaders/fx.pulse.gdshaderinc"
#include "res://shaders/waves.radial.gdshaderinc"
#include "res://shaders/fx.opacity.gdshaderinc"
#include "res://shaders/util.color.gdshaderinc"
#include "res://shaders/waves.secondary.gdshaderinc"


Ctx stage_setup(vec2 uv, float time, sampler2D tex) {
    Ctx c;
    c.uv = uv + wave_offset;
    c.t  = time + time_offset;
	c.speed = wave_speed;

	c.base_pixel = texture(tex, c.uv);

	c.color = c.base_pixel.rgb;
    c.alpha  = c.base_pixel.a;

    c.w1 = c.w2 = c.pulse_wave = 0.0;
    c.uv_scale = uv_scale;
    return c;
}

void fragment() {
	Ctx c = stage_setup(UV, TIME, TEXTURE);

	c = stage_pixelate(c);
	c = stage_noise(c);

	switch (primary_waveform) {
		case WAVE_RADIAL:
			c = stage_radial_effects(c);
			break;
		case WAVE_LINEAR:
		default:
			c = stage_linear_effects(c);
			break;
	}

	c = stage_secondary_waves(c);
	c = stage_pulse_effect(c);
	c = stage_brightness_bias(c);
	c = stage_rainbow_modulation(c);
	c = stage_opacity(c);

	if (enable) {
		// Apply effect opacity control - blend between original and modified colors
		c.color = mix(c.base_pixel.rgb, c.color, c.alpha);
	} else {
		c.color = c.base_pixel.rgb;
		c.alpha  = c.base_pixel.a;
	}

	COLOR = vec4(c.color, c.alpha);
}