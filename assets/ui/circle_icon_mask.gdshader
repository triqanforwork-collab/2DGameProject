shader_type canvas_item;

uniform float radius : hint_range(0.0, 0.5, 0.001) = 0.5;
uniform float edge_softness : hint_range(0.0, 0.05, 0.001) = 0.012;

void fragment() {
	float distance_to_center = distance(UV, vec2(0.5));
	float circle_alpha = 1.0 - smoothstep(radius - edge_softness, radius, distance_to_center);
	COLOR.a *= circle_alpha;
}
