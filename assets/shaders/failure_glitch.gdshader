shader_type canvas_item;

uniform float saturation_intensity : hint_range(0.0, 5.0) = 2.0;
uniform float red_tint : hint_range(0.0, 3.0) = 1.5;
uniform float visibility : hint_range(0.0, 1.0) = 0.0;
uniform float noise_amount : hint_range(0.0, 1.0) = 0.3;
uniform float distortion_strength : hint_range(0.0, 0.1) = 0.02;

// Simple noise function
float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    // Add distortion to UV coordinates for a glitch effect
    vec2 distorted_uv = UV;
    float noise = random(UV + TIME * 0.5);
    distorted_uv.x += sin(UV.y * 10.0 + TIME * 2.0) * distortion_strength * visibility;
    distorted_uv.y += cos(UV.x * 15.0 + TIME * 3.0) * distortion_strength * visibility;

    // Clamp UV to prevent sampling outside texture
    distorted_uv = clamp(distorted_uv, vec2(0.0), vec2(1.0));

    vec4 tex_color = texture(TEXTURE, distorted_uv);

    // Apply red tint and saturation
    vec3 saturated_color = tex_color.rgb;

    // Increase saturation dramatically for glitch effect
    float gray = dot(saturated_color, vec3(0.299, 0.587, 0.114));
    saturated_color = mix(vec3(gray), saturated_color, saturation_intensity);

    // Add strong red tint for distortion
    saturated_color.r *= red_tint;
    saturated_color.g *= 0.5; // Heavily reduce green
    saturated_color.b *= 0.3; // Heavily reduce blue

    // Add glitch noise (red-tinted static)
    float glitch_noise = random(UV + TIME * 0.8) * noise_amount;
    saturated_color += vec3(glitch_noise * 0.3, glitch_noise * 0.1, 0.0);

    // Mix with original based on visibility (transparent overlay effect)
    vec3 final_color = mix(tex_color.rgb, saturated_color, visibility);

    // Keep the original alpha but make the effect semi-transparent
    COLOR = vec4(final_color, tex_color.a * (0.3 + visibility * 0.7));
}
