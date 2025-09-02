group_uniforms Pixelation;

/** Enable pixelation effect */
uniform bool  enable_pixelation = false;
/** Pixel size (higher = larger pixels, more pixelated) */
uniform float pixelation_size   : hint_range(1.0,10.0)=3.0;

Ctx stage_pixelate(Ctx c){
	if (enable_pixelation) {
		float squared_size = pixelation_size * pixelation_size; // Square the slider value
		vec2 pixel_size = vec2(squared_size) / c.uv_scale; // Convert to UV space
		c.uv = floor(c.uv / pixel_size) * pixel_size + pixel_size * 0.5;
		c.uv = clamp(c.uv, 0.0, 1.0);
	}
    return c;
}
