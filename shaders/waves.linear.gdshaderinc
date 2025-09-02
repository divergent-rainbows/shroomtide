group_uniforms BasicWaves;
/** Speed of wave animation */
uniform float wave_speed : hint_range(0.0, 100.0) = 10.0;
/** Wave size (lower = smaller waves, higher = larger waves) */
uniform vec2 wave_scale = vec2(5.0, 5.0);
/** Horizontal wave movement direction and speed */
uniform vec2 wave_direction = vec2(1,1);

Ctx stage_linear_effects(Ctx c){

    c.w1 = sin(
            c.uv.x /  (wave_scale.x / c.uv_scale) + 
            c.t * c.speed * wave_direction.x
        ) + cos(
            c.uv.y /  (wave_scale.y / c.uv_scale) + 
            c.t * c.speed * wave_direction.y
        );
    return c;
}