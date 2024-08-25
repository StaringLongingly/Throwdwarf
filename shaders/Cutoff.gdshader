shader_type canvas_item;

uniform float cutoff: hint_range(0.0, 1.0) = 0.5;
uniform vec4 modulate = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	// Calculate the adjusted UV.y based on the cutoff value
	float adjusted_y = UV.y + (cutoff - 1.0);

	// Check if the adjusted UV.y is within bounds
	if (adjusted_y < 0.0 || adjusted_y > 1.0) {
		discard;
	} else {
		// Sample the texture with the adjusted UV coordinates
		vec2 adjusted_uv = vec2(UV.x, adjusted_y);
		COLOR = texture(TEXTURE, adjusted_uv) * modulate;
	}
}