shader_type canvas_item;

uniform sampler2D star_tex;
uniform float scale = 1.0; // controls zoom of the galaxy texture
uniform vec4 tint_color : source_color = vec4(5.0);
uniform float speed = 0.05;
void fragment() {
    // Get screen aspect ratio
    vec2 screen_size = 1.0 / SCREEN_PIXEL_SIZE;
    float aspect = screen_size.x / screen_size.y;
    
    // Apply aspect ratio correction to UVs
    vec2 screen_uv = SCREEN_UV;
    screen_uv.x *= aspect;  // Stretch horizontally to compensate
    
    // Add scrolling and scale, then wrap
    screen_uv = fract((screen_uv + vec2(TIME * speed, 0.0)) * scale);
    
    vec4 star_col = texture(star_tex, screen_uv);
    star_col.rgb *= 1.5;
    
    COLOR = star_col * tint_color * texture(TEXTURE, UV).a;
}
