shader_type canvas_item;

uniform float progress: hint_range(0.0, 1.0) = 0.5;
uniform float angle = 0.5;
uniform vec4 modulate = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    // Remap progress2 from [0, 1] to [angle, 1]
    float progress2 = (1.0 + 1.0 / angle) * progress - 1.0 / angle;
    
    // Calculate the triangle shape based on remapped progress2
    float triangle = angle / 2.0 * (UV.x - progress2);

    // Check if UV.y is within bounds
    if (UV.y <= triangle || UV.y >= 1.0 - triangle) {
        discard;
    } else {
        // Sample the texture with the adjusted UV coordinates
        COLOR *= modulate;
    }
}