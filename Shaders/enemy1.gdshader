shader_type canvas_item;

uniform bool flash = false;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (flash) {
		// Whiteout effect while keeping alpha
		COLOR = vec4(1.0, 1.0, 1.0, tex.a);
	} else {
		COLOR = tex;
	}
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
