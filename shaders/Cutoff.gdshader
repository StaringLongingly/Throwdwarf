shader_type canvas_item;

uniform float cutoff: hint_range(0.0, 1.0) = 0.5;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	float threshhold = UV.y;
	vec2 adjusted_uv = UV;
	adjusted_uv.y = UV.y + (cutoff - 1.0);
	
	if (adjusted_uv.y > 1.0) {
		discard;
	} else {
		COLOR = texture(TEXTURE, adjusted_uv);
	}
	// Called for every pixel the material is visible on.
}