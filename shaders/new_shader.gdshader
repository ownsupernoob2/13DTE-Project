shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// Uniforms for controlling the shader
uniform float noise_scale : hint_range(0.1, 10.0) = 2.0; // Controls noise detail
uniform float animation_speed : hint_range(0.0, 2.0) = 0.5; // Controls animation speed
uniform float transparency_strength : hint_range(0.0, 1.0) = 1.0; // Controls max transparency
uniform vec3 color : source_color = vec3(1.0, 1.0, 1.0); // Base color of the sphere
uniform float wobble_strength : hint_range(0.0, 0.5) = 0.1; // Controls wobble intensity
uniform float wobble_speed : hint_range(0.0, 2.0) = 0.1; // Controls wobble animation speed
uniform float wobble_scale : hint_range(0.1, 10.0) = 2.0; // Controls wobble noise detail
uniform sampler2D noise_texture : hint_default_black; // FastNoiseLite texture

// Convert 3D position to spherical UV coordinates
vec2 spherical_uv(vec3 pos) {
    // Normalize position to get direction
    vec3 n = normalize(pos);
    // Compute spherical coordinates (azimuth and inclination)
    float u = atan(n.x, n.z) / (2.0 * 3.14159265) + 0.5; // Azimuth -> [0, 1]
    float v = asin(n.y) / 3.14159265 + 0.5; // Inclination -> [0, 1]
    return vec2(u, v);
}

void vertex() {
    // Compute spherical UVs from vertex position
    vec2 wobble_uv = spherical_uv(VERTEX) * wobble_scale + vec2(TIME * wobble_speed, TIME * wobble_speed * 0.5);

    // Sample noise texture for wobble
    float wobble = texture(noise_texture, wobble_uv).r;

    // Displace vertex along its normal based on noise
    VERTEX += NORMAL * wobble * wobble_strength;
}

void fragment() {
    // Compute spherical UVs from vertex position in world space
    vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    vec2 uv = spherical_uv(world_pos) * noise_scale;
    uv += vec2(TIME * animation_speed, TIME * animation_speed * 0.5);

    // Sample noise texture
    float n = texture(noise_texture, uv).r;

    // Map noise to transparency (darker = more transparent)
    float alpha = 1.0 - n * transparency_strength;

    // Set albedo (color) and transparency
    ALBEDO = color;
    ALPHA = clamp(alpha, 0.0, 1.0);
}