shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform float fog_density : hint_range(0.0, 1.0) = 0.5;
uniform float fog_speed : hint_range(0.0, 2.0) = 0.3;
uniform float fog_scale : hint_range(0.1, 10.0) = 2.0;
uniform vec3 fog_color : source_color = vec3(0.1, 0.1, 0.2);
uniform float animation_strength : hint_range(0.0, 1.0) = 0.5;

varying vec3 world_position;
varying float noise;

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise2d(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
           (c - a) * u.y * (1.0 - u.x) +
           (d - b) * u.x * u.y;
}

void vertex() {
    world_position = VERTEX;

    // Add some vertex displacement for organic movement
    vec3 displaced_vertex = VERTEX;
    float time_offset = TIME * fog_speed;

    displaced_vertex.x += sin(time_offset + VERTEX.y * 2.0) * 0.1 * animation_strength;
    displaced_vertex.z += cos(time_offset + VERTEX.x * 2.0) * 0.1 * animation_strength;
    displaced_vertex.y += sin(time_offset * 0.5 + VERTEX.x + VERTEX.z) * 0.05 * animation_strength;

    VERTEX = displaced_vertex;
}

void fragment() {
    vec2 uv = world_position.xz * fog_scale;
    uv += vec2(TIME * fog_speed * 0.5, TIME * fog_speed * 0.3);

    // Generate layered noise for volumetric effect
    float n1 = noise2d(uv);
    float n2 = noise2d(uv * 2.0 + vec2(TIME * fog_speed, 0.0)) * 0.5;
    float n3 = noise2d(uv * 4.0 - vec2(0.0, TIME * fog_speed * 0.8)) * 0.25;

    float combined_noise = n1 + n2 + n3;

    // Distance-based fade
    float distance_fade = 1.0 - smoothstep(0.0, 10.0, length(world_position));

    // Calculate alpha based on noise and distance
    float alpha = combined_noise * fog_density * distance_fade;
    alpha = clamp(alpha, 0.0, 0.9);

    ALBEDO = fog_color;
    ALPHA = alpha;
    EMISSION = fog_color * 0.1;
}
