shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// Uniforms for controlling the shader
uniform float noise_scale : hint_range(0.1, 90.0) = 50.0; // Controls noise detail
uniform float animation_speed : hint_range(0.0, 2.0) = 0.5; // Controls animation speed
uniform float transparency_strength : hint_range(0.0, 1.0) = 1.0; // Controls max transparency
uniform vec3 color : source_color = vec3(1.0, 0.5, 0.2); // Base color (warm lava-like tone)
uniform float wobble_strength : hint_range(0.0, 0.5) = 0.2; // Controls wobble intensity
uniform float wobble_speed : hint_range(0.0, 2.0) = 0.3; // Controls wobble animation speed
uniform float wobble_scale : hint_range(0.1, 10.0) = 2.0; // Controls wobble noise detail
uniform float rotation_speed : hint_range(0.0, 1.0) = 0.2; // Controls rotation speed
uniform sampler2D noise_texture : hint_default_black; // FastNoiseLite texture

void vertex() {
    // Transform vertex to object space for consistent wobble
    vec3 object_pos = VERTEX * wobble_scale;

    // Add rotation over time for spinning effect
    float angle = TIME * rotation_speed;
    mat2 rotation = mat2(vec2(cos(angle), -sin(angle)), vec2(sin(angle), cos(angle)));
    object_pos.xz = rotation * object_pos.xz;

    // Animate noise sampling with time for organic morphing
    vec3 wobble_uv = object_pos + vec3(TIME * wobble_speed, TIME * wobble_speed * 0.5, TIME * wobble_speed * 0.3);

    // Sample noise texture for wobble
    float wobble = texture(noise_texture, wobble_uv.xy).r;

    // Displace vertex along its normal based on noise
    VERTEX += NORMAL * wobble * wobble_strength;
}

void fragment() {
    // Use object-space position for noise, not UV, to avoid camera dependency
    vec3 object_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    object_pos *= noise_scale;

    // Animate noise with time for flowing lava effect
    object_pos += vec3(TIME * animation_speed, TIME * animation_speed * 0.5, TIME * animation_speed * 0.3);

    // Sample noise texture
    float n = texture(noise_texture, object_pos.xy).r;

    // Add layered noise for more organic variation
    float n2 = texture(noise_texture, object_pos.xy * 0.5 + vec2(TIME * animation_speed * 0.2)).r;
    n = (n + n2 * 0.5) * 0.666; // Combine for smoother, blob-like patterns

    // Map noise to transparency (darker = more transparent)
    float alpha = 1.0 - n * transparency_strength;

    // Set albedo (color) and transparency
    ALBEDO = color;
    ALPHA = clamp(alpha, 0.0, 1.0);
}