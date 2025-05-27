shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// Uniforms for controlling the fluid effect
uniform float speed = 1.0; // Speed of the fluid animation
uniform float noise_scale = 0.5; // Scale of the noise pattern
uniform float displacement_strength = 0.1; // Strength of vertex displacement
uniform vec3 color = vec3(0.2, 0.5, 0.8); // Base color of the fluid
uniform float metallic = 0.3; // Metallic property
uniform float roughness = 0.5; // Roughness property

// Simplex noise function for 3D
float simplex_noise(vec3 p) {
    // Simple 3D simplex noise implementation
    vec3 s = floor(p + dot(p, vec3(0.333333)));
    vec3 x = p - s + dot(s, vec3(0.166666));
    vec3 e = step(vec3(0.0), x - x.yzx);
    vec3 i1 = e * (1.0 - e.zxy);
    vec3 i2 = 1.0 - e.zxy * (1.0 - e);
    vec3 x1 = x - i1 + 0.166666;
    vec3 x2 = x - i2 + 0.333333;
    vec3 x3 = x - 0.5;
    vec4 w, d;
    w.x = dot(x, x);
    w.y = dot(x1, x1);
    w.z = dot(x2, x2);
    w.w = dot(x3, x3);
    w = max(0.6 - w, 0.0);
    w = w * w;
    w = w * w;
    d.x = dot(fract(sin(s * 103.0) * 43758.5453), vec3(0.666));
    d.y = dot(fract(sin((s + i1) * 103.0) * 43758.5453), vec3(0.666));
    d.z = dot(fract(sin((s + i2) * 103.0) * 43758.5453), vec3(0.666));
    d.w = dot(fract(sin((s + 1.0) * 103.0) * 43758.5453), vec3(0.666));
    return dot(w, d);
}

// Main vertex function
void vertex() {
    // Animate vertex position using noise
    vec3 world_pos = VERTEX;
    float noise = simplex_noise(world_pos * noise_scale + TIME * speed);
    VERTEX += NORMAL * noise * displacement_strength;
}

// Main fragment function
void fragment() {
    // Sample noise for albedo variation
    vec3 world_pos = VERTEX;
    float noise = simplex_noise(world_pos * noise_scale + TIME * speed);
    
    // Create fluid-like color variation
    vec3 albedo = color * (0.8 + 0.2 * noise);
    
    // Set material properties
    ALBEDO = albedo;
    METALLIC = metallic;
    ROUGHNESS = roughness;
    
    // Add slight emissive effect based on noise
    EMISSION = albedo * 0.2 * abs(sin(noise * 3.14159));
}