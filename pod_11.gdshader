shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// Uniforms for controlling noise, rotation, wobble, and transparency
uniform float noise_scale : hint_range(0.1, 10.0) = 2.0; // Controls noise frequency
uniform float rotation_speed : hint_range(0.0, 1.0) = 0.1; // Speed of rotation
uniform float wobble_amplitude : hint_range(0.0, 0.1) = 0.02; // Subtle wobble strength
uniform float transparency_strength : hint_range(0.0, 1.0) = 0.8; // How much darkness affects transparency
uniform vec3 rotation_axis = vec3(0.0, 1.0, 0.0); // Axis of rotation (default Y-axis)

// Custom 3D Simplex noise implementation
vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec4 mod289(vec4 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec4 permute(vec4 x) { return mod289(((x * 34.0) + 1.0) * x); }
vec4 taylorInvSqrt(vec4 r) { return 1.79284291400159 - 0.85373472095314 * r; }

float simplex_noise(vec3 v) {
    const vec2 C = vec2(1.0 / 6.0, 1.0 / 3.0);
    const vec4 D = vec4(0.0, 0.5, 1.0, 2.0);

    // First corner
    vec3 i = floor(v + dot(v, vec3(C.y)));
    vec3 x0 = v - i + dot(i, vec3(C.x));

    // Other corners
    vec3 g = step(x0.yzx, x0.xyz);
    vec3 l = 1.0 - g;
    vec3 i1 = min(g.xyz, l.zxy);
    vec3 i2 = max(g.xyz, l.zxy);

    vec3 x1 = x0 - i1 + vec3(C.x);
    vec3 x2 = x0 - i2 + vec3(C.y);
    vec3 x3 = x0 - vec3(D.y);

    // Permutations
    i = mod289(i);
    vec4 p = permute(permute(permute(
                i.z + vec4(0.0, i1.z, i2.z, 1.0))
                + i.y + vec4(0.0, i1.y, i2.y, 1.0))
                + i.x + vec4(0.0, i1.x, i2.x, 1.0));

    // Gradients
    vec3 ns = vec3(1.0 / 7.0, 2.0 / 7.0, -1.0 / 7.0) * D.z;
    vec4 j = p - 49.0 * floor(p * ns.z * ns.z);
    vec4 x_ = floor(j * ns.z);
    vec4 y_ = floor(j - 7.0 * x_);
    vec4 x = x_ * ns.x + ns.yyyy;
    vec4 y = y_ * ns.x + ns.yyyy;
    vec4 h = 1.0 - abs(x) - abs(y);
    vec4 b0 = vec4(x.xy, y.xy);
    vec4 b1 = vec4(x.zw, y.zw);
    vec4 s0 = floor(b0) * 2.0 + 1.0;
    vec4 s1 = floor(b1) * 2.0 + 1.0;
    vec4 sh = -step(h, vec4(0.0));
    vec4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
    vec4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
    vec3 p0 = vec3(a0.xy, h.x);
    vec3 p1 = vec3(a0.zw, h.y);
    vec3 p2 = vec3(a1.xy, h.z);
    vec3 p3 = vec3(a1.zw, h.w);

    // Normalize gradients
    vec4 norm = taylorInvSqrt(vec4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
    p0 *= norm.x;
    p1 *= norm.y;
    p2 *= norm.z;
    p3 *= norm.w;

    // Mix final noise value
    vec4 m = max(0.6 - vec4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
    m = m * m;
    return 42.0 * dot(m * m, vec4(dot(p0, x0), dot(p1, x1), dot(p2, x2), dot(p3, x3)));
}

// Rotation matrix around an arbitrary axis
mat3 rotation_matrix(vec3 axis, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    float t = 1.0 - c;
    vec3 normalized_axis = normalize(axis);
    float x = normalized_axis.x;
    float y = normalized_axis.y;
    float z = normalized_axis.z;

    return mat3(
        vec3(t * x * x + c, t * x * y - s * z, t * x * z + s * y),
        vec3(t * x * y + s * z, t * y * y + c, t * y * z - s * x),
        vec3(t * x * z - s * y, t * y * z + s * x, t * z * z + c)
    );
}

void vertex() {
    // Apply slow rotation with subtle wobble
    float time = TIME * rotation_speed;
    float wobble = sin(TIME * 0.5) * wobble_amplitude; // Slow wobble effect
    mat3 rot = rotation_matrix(rotation_axis, time + wobble);
    VERTEX = rot * VERTEX;
}

void fragment() {
    // Sample noise based on 3D UV coordinates for seamless effect
    vec3 noise_pos = VERTEX * noise_scale;
    float noise_value = simplex_noise(noise_pos);

    // Map noise value (-1 to 1) to 0-1 range for albedo and alpha
    float normalized_noise = (noise_value + 1.0) * 0.5;

    // Darker noise = more transparent
    float alpha = 1.0 - (normalized_noise * transparency_strength);

    // Set albedo (grayscale noise texture) and transparency
    ALBEDO = vec3(normalized_noise);
    ALPHA = clamp(alpha, 0.0, 1.0);
}