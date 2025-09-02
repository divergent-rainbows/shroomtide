/** Wave acceleration type (0=None, 1=Exponential, 2=Gradient) */
uniform int acceleration_type : hint_enum("None", "Exponential", "Gradient") = 0;
/** Wave acceleration strength for exponential mode */
uniform float wave_acceleration : hint_range(-10.0, 10.0) = 0.0;
/** Wave density at inner radius (higher = more waves) */
uniform float gradient_inner_density : hint_range(0.1, 10.0) = 1.0;
/** Wave density at middle point (higher = more waves) */
uniform float gradient_middle_density : hint_range(0.1, 10.0) = 1.0;
/** Wave density at outer radius (higher = more waves) */
uniform float gradient_outer_density : hint_range(0.1, 10.0) = 1.0;
/** Inner radius for opacity transition start */
uniform float inner_radius : hint_range(0.0, 2.0) = 0.3;
/** Outer radius for opacity transition end */
uniform float outer_radius : hint_range(0.1, 2.0) = 0.7;

Ctx stage_radial_acceleration(Ctx c){
    switch (acceleration_type) {
			case ACCEL_GRADIENT:
				// Apply radial gradient with 3-point interpolation
				float middle_radius = (inner_radius + outer_radius) * 0.5;
				bool in_inner_region = (c.distance_from_center <= middle_radius);
				// Determine which segment we're in and interpolate density
				float t = in_inner_region
					? (c.distance_from_center - inner_radius) / (middle_radius - inner_radius)
					: (c.distance_from_center - middle_radius) / (outer_radius - middle_radius);
				t = clamp(t, 0.0, 1.0);
				float density_multiplier = mix(gradient_inner_density,
					in_inner_region ? gradient_middle_density : gradient_outer_density, t);
				c.distance_based_frequency = radial_frequency * density_multiplier;
				break;

			case ACCEL_EXPONENTIAL:
				// Apply exponential frequency acceleration normalized to preserve inner wave frequency
				// This creates true acceleration where wave spacing changes exponentially with distance
				// Convert wave_acceleration to exponential base
				float acceleration_base = 1.0 + wave_acceleration / 1000.0;
				// Normalize so frequency at reference distance equals base frequency
				// f(d) = base_f * (base ^ ref_dist) / (base ^ distance)
				float normalization_factor = pow(acceleration_base, inner_radius);
				c.distance_based_frequency = 
						radial_frequency * normalization_factor 
					/ 	pow(acceleration_base, c.distance_from_center);
				break;

			case ACCEL_NONE:
			default:
				// No acceleration, keep base frequency
				c.distance_based_frequency = pow(radial_frequency, 2);
				break;
		}
    return c;
}