shader_type canvas_item;

uniform float contaminacion : hint_range(0.0, 1.0) = 0.0;
uniform float tiempo : hint_range(0.0, 100.0) = 0.0;
uniform sampler2D fondo_contaminado;

void fragment() {
    vec4 color_limpio = texture(TEXTURE, UV);
    vec4 color_sucio = texture(fondo_contaminado, UV);
    
    float smog = sin(UV.x * 6.0 + tiempo * 0.3) *
                 cos(UV.y * 4.0 + tiempo * 0.2) * 0.5 + 0.5;
    float smog2 = sin(UV.x * 10.0 - tiempo * 0.25) *
                  sin(UV.y * 8.0 + tiempo * 0.15) * 0.5 + 0.5;
    float smog_total = mix(smog, smog2, 0.5) * contaminacion * 0.3;
    
    vec4 color_final = mix(color_limpio, color_sucio, contaminacion);
    
    float vignette = length(UV - vec2(0.5)) * contaminacion * 2.0;
    color_final.rgb -= vignette * 0.4;
    
    color_final.rgb = mix(color_final.rgb, vec3(0.3, 0.28, 0.2), smog_total);
    
    COLOR = color_final;
}