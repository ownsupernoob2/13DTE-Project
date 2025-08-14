shader_type spatial;
render_mode unshaded, depth_test_disabled, cull_disabled;


uniform sampler2D screen_texture : hint_screen_texture;

void vertex(){
	// needs to be 1.0
	VERTEX *= 1.0;
	// needs to be 1.0
	POSITION = vec4(VERTEX, 1.0);
}

void fragment() {
	vec2 texCoords = SCREEN_UV;
	vec3 color = texture(screen_texture, SCREEN_UV).rgb;
	float lum = pow(dot(color, vec3(1.0, 0, 0)), 1.2);
	float brightness = (color.r * color.g * color.b)/0.1;
	vec3 grayScale = vec3(brightness, brightness, brightness);
	color = grayScale;
	ALBEDO = color.rgb * lum;
}