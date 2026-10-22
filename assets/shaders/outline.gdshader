shader_type canvas_item;
// Контур вокруг непрозрачных пикселей спрайта (элитные враги).

uniform vec4 outline_color : source_color = vec4(1.0, 0.8, 0.25, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a > 0.1) {
		COLOR = tex * COLOR;
	} else {
		vec2 px = TEXTURE_PIXEL_SIZE;
		float around = texture(TEXTURE, UV + vec2(px.x, 0.0)).a + texture(TEXTURE, UV - vec2(px.x, 0.0)).a
			+ texture(TEXTURE, UV + vec2(0.0, px.y)).a + texture(TEXTURE, UV - vec2(0.0, px.y)).a;
		COLOR = around > 0.1 ? outline_color : vec4(0.0);
	}
}
