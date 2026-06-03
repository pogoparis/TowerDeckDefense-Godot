shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 0.85, 0.2, 1.0);
uniform float outline_size = 3.0;

void fragment()
{
	vec4 col = texture(TEXTURE, UV);

	float a = col.a;

	float left  = texture(TEXTURE, UV + vec2(-outline_size, 0.0) * TEXTURE_PIXEL_SIZE).a;
	float right = texture(TEXTURE, UV + vec2( outline_size, 0.0) * TEXTURE_PIXEL_SIZE).a;
	float up    = texture(TEXTURE, UV + vec2(0.0, -outline_size) * TEXTURE_PIXEL_SIZE).a;
	float down  = texture(TEXTURE, UV + vec2(0.0,  outline_size) * TEXTURE_PIXEL_SIZE).a;

	float outline = max(max(left,right), max(up,down));

	if (a < 0.01 && outline > 0.01)
	{
		COLOR = outline_color;
	}
	else
	{
		COLOR = col;
	}
}