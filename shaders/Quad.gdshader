shader_type canvas_item;

uniform int id = 0;

void fragment() {
	float threshhold = UV.y;
	vec2 adjusted_uv = UV;
	bool isAllowed;
	if (id % 4 == 0)
		isAllowed = UV.x > 0.5 && UV.y > 0.5;
	else if (id % 4 == 1)
		isAllowed = UV.x > 0.5 && UV.y < 0.5;
	else if (id % 4 == 2)
		isAllowed = UV.x < 0.5 && UV.y < 0.5;
	else if (id % 4 == 3)
		isAllowed = UV.x < 0.5 && UV.y > 0.5;


	if (!isAllowed) {
		discard;
	} else {
		COLOR = texture(TEXTURE, UV);
	}
	// Called for every pixel the material is visible on.
}