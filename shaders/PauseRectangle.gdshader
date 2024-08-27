shader_type canvas_item;
uniform float black = 0.5;

void fragment() {
	COLOR = COLOR * vec4(black, black, black, 1);
	// Called for every pixel the material is visible on.
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
