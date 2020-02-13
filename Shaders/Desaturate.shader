shader_type canvas_item;
render_mode unshaded;

uniform float desaturation = 0.0;

vec3 grayscale(vec3 input_color)
{
    float gray = dot(input_color.rgb, vec3(0.2126, 0.7152, 0.0722));
    return vec3(gray, gray, gray);
}

void fragment()
{
	COLOR = texture(TEXTURE, UV);
	COLOR.rgb = mix(COLOR.rgb, grayscale(COLOR.rbg), desaturation);
}