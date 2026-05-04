shader_type canvas_item;

uniform vec2 offset = vec2(4.0, 4.0);
uniform vec4 color_sombra : source_color = vec4(0.0, 0.0, 0.0, 0.4);

void fragment() {
    vec2 uv_sombra = UV - offset * TEXTURE_PIXEL_SIZE;
    float alpha_sombra = texture(TEXTURE, uv_sombra).a;
    vec4 color_base = texture(TEXTURE, UV);
    vec4 sombra = color_sombra * alpha_sombra * (1.0 - color_base.a);
    COLOR = color_base + sombra;
}