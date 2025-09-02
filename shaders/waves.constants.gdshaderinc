// Wavef constants
const int WAVE_LINEAR  = 0;
const int WAVE_RADIAL  = 1;

// Acceleration type constants
const int ACCEL_NONE        = 0;
const int ACCEL_EXPONENTIAL = 1;
const int ACCEL_GRADIENT    = 2;

struct Ctx {
    vec2 uv;
	float uv_scale;
    float t;          // TIME + offset (seconds)
    float speed;

    // Source
    vec4 base_pixel;   

    // Radial calculations
    float distance_from_center;
    float distance_based_frequency;

    // Signal
    float w1;         // primary wave
    float w2;         // secondary wave
    float pulse_wave;

    // Color
    vec3 color;         // working color
    float alpha;          // working alpha
};