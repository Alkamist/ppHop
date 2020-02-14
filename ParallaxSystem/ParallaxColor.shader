shader_type canvas_item;
render_mode unshaded;

uniform vec4 fade_color : hint_color;
uniform float tint_strength = 0.0;

void fragment()
{
	COLOR = texture(TEXTURE, UV);
	COLOR.rgb = mix(COLOR.rgb, fade_color.rgb, tint_strength);
}