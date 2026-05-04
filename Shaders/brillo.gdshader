shader_type canvas_item;

uniform float intensidad : hint_range(0.0, 1.0) = 0.4;

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    color.rgb += vec3(intensidad) * color.a;
    COLOR = color;
}