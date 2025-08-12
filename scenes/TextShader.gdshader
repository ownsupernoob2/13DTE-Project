shader_type canvas_item;

// === GLITCH INTENSITY CONTROLS ===
group_uniforms glitch_intensity;
uniform float glitch_strength : hint_range(0.0, 1.0) = 0.5;
uniform float glitch_frequency : hint_range(0.1, 10.0) = 2.0;
uniform float glitch_speed : hint_range(0.1, 5.0) = 1.0;

// === RGB SPLIT / CHROMATIC ABERRATION ===
group_uniforms rgb_split;
uniform bool enable_rgb_split = true;
uniform float rgb_split_intensity : hint_range(0.0, 0.1) = 0.01;
uniform float rgb_split_angle : hint_range(0.0, 360.0) = 0.0;
uniform bool rgb_split_random_direction = false;

// === HORIZONTAL DISTORTION ===
group_uniforms horizontal_distortion;
uniform bool enable_horizontal_glitch = true;
uniform float h_glitch_intensity : hint_range(0.0, 0.5) = 0.1;
uniform float h_glitch_block_size : hint_range(0.001, 0.1) = 0.02;
uniform float h_glitch_threshold : hint_range(0.0, 1.0) = 0.8;

// === VERTICAL DISTORTION ===
group_uniforms vertical_distortion;
uniform bool enable_vertical_glitch = false;
uniform float v_glitch_intensity : hint_range(0.0, 0.5) = 0.05;
uniform float v_glitch_block_size : hint_range(0.001, 0.1) = 0.01;
uniform float v_glitch_threshold : hint_range(0.0, 1.0) = 0.9;

// === DIGITAL NOISE ===
group_uniforms digital_noise;
uniform bool enable_digital_noise = true;
uniform float noise_intensity : hint_range(0.0, 1.0) = 0.3;
uniform float noise_size : hint_range(0.1, 50.0) = 10.0;
uniform vec3 noise_color : source_color = vec3(1.0, 1.0, 1.0);

// === SCANLINES ===
group_uniforms scanlines;
uniform bool enable_scanlines = false;
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.3;
uniform float scanline_frequency : hint_range(10.0, 1000.0) = 200.0;
uniform float scanline_speed : hint_range(0.0, 10.0) = 2.0;

// === INTERLACING ===
group_uniforms interlacing;
uniform bool enable_interlacing = false;
uniform float interlace_intensity : hint_range(0.0, 1.0) = 0.5;
uniform float interlace_frequency : hint_range(2.0, 20.0) = 4.0;

// === DATA CORRUPTION ===
group_uniforms data_corruption;
uniform bool enable_data_corruption = false;
uniform float corruption_intensity : hint_range(0.0, 1.0) = 0.2;
uniform float corruption_block_size : hint_range(0.001, 0.05) = 0.01;
uniform float corruption_threshold : hint_range(0.0, 1.0) = 0.95;

// === COLOR MANIPULATION ===
group_uniforms color_effects;
uniform bool enable_color_shift = false;
uniform float color_shift_intensity : hint_range(0.0, 1.0) = 0.3;
uniform float hue_shift_speed : hint_range(0.0, 10.0) = 1.0;
uniform bool enable_posterize = false;
uniform int posterize_levels : hint_range(2, 16) = 8;

// === GLITCH TIMING ===
group_uniforms timing_controls;
uniform bool use_pulse_mode = false;
uniform float pulse_frequency : hint_range(0.1, 10.0) = 1.0;
uniform float pulse_width : hint_range(0.1, 0.9) = 0.3;
uniform bool random_glitch_timing = true;

// === MASKING ===
group_uniforms masking;
uniform bool enable_mask = false;
uniform sampler2D glitch_mask : hint_default_black;
uniform bool invert_mask = false;

// Noise function
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// Hash function for better randomness
float hash21(vec2 p) {
    p = fract(p * vec2(233.34, 851.73));
    p += dot(p, p + 23.45);
    return fract(p.x * p.y);
}

// RGB to HSV conversion
vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// HSV to RGB conversion
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
    vec2 uv = UV;
    float time_factor = TIME * glitch_speed;
    
    // Calculate glitch timing
    float glitch_timing = 1.0;
    if (use_pulse_mode) {
        float pulse_time = mod(TIME * pulse_frequency, 1.0);
        glitch_timing = step(pulse_time, pulse_width);
    }
    if (random_glitch_timing) {
        glitch_timing *= step(0.5, random(floor(TIME * glitch_frequency) * vec2(1.0, 1.0)));
    }
    
    // Apply mask if enabled
    float mask_value = 1.0;
    if (enable_mask) {
        mask_value = texture(glitch_mask, uv).r;
        if (invert_mask) mask_value = 1.0 - mask_value;
    }
    
    float effective_strength = glitch_strength * glitch_timing * mask_value;
    
    // === HORIZONTAL GLITCH ===
    if (enable_horizontal_glitch) {
        float block_y = floor(uv.y / h_glitch_block_size) * h_glitch_block_size;
        float noise_h = random(vec2(block_y, floor(time_factor * 10.0)));
        
        if (noise_h > h_glitch_threshold) {
            float displacement = (random(vec2(block_y, time_factor)) - 0.5) * h_glitch_intensity * effective_strength;
            uv.x += displacement;
        }
    }
    
    // === VERTICAL GLITCH ===
    if (enable_vertical_glitch) {
        float block_x = floor(uv.x / v_glitch_block_size) * v_glitch_block_size;
        float noise_v = random(vec2(block_x, floor(time_factor * 8.0)));
        
        if (noise_v > v_glitch_threshold) {
            float displacement = (random(vec2(block_x, time_factor)) - 0.5) * v_glitch_intensity * effective_strength;
            uv.y += displacement;
        }
    }
    
    // === RGB SPLIT / CHROMATIC ABERRATION ===
    vec4 final_color;
    if (enable_rgb_split) {
        vec2 offset_direction = vec2(cos(radians(rgb_split_angle)), sin(radians(rgb_split_angle)));
        if (rgb_split_random_direction) {
            float random_angle = random(floor(time_factor * 5.0) * vec2(1.0)) * 6.28318;
            offset_direction = vec2(cos(random_angle), sin(random_angle));
        }
        
        vec2 offset = offset_direction * rgb_split_intensity * effective_strength;
        
        float r = texture(TEXTURE, uv + offset).r;
        float g = texture(TEXTURE, uv).g;
        float b = texture(TEXTURE, uv - offset).b;
        float a = texture(TEXTURE, uv).a;
        
        final_color = vec4(r, g, b, a);
    } else {
        final_color = texture(TEXTURE, uv);
    }
    
    // === DATA CORRUPTION ===
    if (enable_data_corruption && effective_strength > 0.0) {
        vec2 block_pos = floor(uv / corruption_block_size) * corruption_block_size;
        float corruption_noise = random(vec2(block_pos.x + block_pos.y, floor(time_factor * 15.0)));
        
        if (corruption_noise > corruption_threshold) {
            vec3 corrupt_color = vec3(
                random(block_pos + vec2(1.0, 0.0)),
                random(block_pos + vec2(0.0, 1.0)),
                random(block_pos + vec2(1.0, 1.0))
            );
            final_color.rgb = mix(final_color.rgb, corrupt_color, corruption_intensity * effective_strength);
        }
    }
    
    // === DIGITAL NOISE ===
    if (enable_digital_noise && effective_strength > 0.0) {
        vec2 noise_uv = uv * noise_size;
        float noise_val = random(floor(noise_uv) + floor(time_factor * 20.0) * vec2(1.0));
        vec3 noise_contribution = noise_color * noise_val * noise_intensity * effective_strength;
        final_color.rgb = mix(final_color.rgb, final_color.rgb + noise_contribution, 0.5);
    }
    
    // === SCANLINES ===
    if (enable_scanlines) {
        float scanline = sin((uv.y + TIME * scanline_speed * 0.1) * scanline_frequency) * 0.5 + 0.5;
        scanline = pow(scanline, 3.0);
        final_color.rgb *= mix(1.0, scanline, scanline_intensity);
    }
    
    // === INTERLACING ===
    if (enable_interlacing) {
        float interlace_line = mod(floor(uv.y * interlace_frequency), 2.0);
        final_color.rgb *= mix(1.0, 0.5, interlace_intensity * interlace_line);
    }
    
    // === COLOR EFFECTS ===
    if (enable_color_shift) {
        vec3 hsv = rgb2hsv(final_color.rgb);
        hsv.x += sin(TIME * hue_shift_speed) * color_shift_intensity;
        hsv.x = fract(hsv.x);
        final_color.rgb = hsv2rgb(hsv);
    }
    
    if (enable_posterize && posterize_levels > 1) {
        float levels = float(posterize_levels);
        final_color.rgb = floor(final_color.rgb * levels) / levels;
    }
    
    COLOR = final_color;
}