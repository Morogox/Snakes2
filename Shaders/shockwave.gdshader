shader_type canvas_item;

uniform float distortion_strength : hint_range(0.0, 0.2) = 0.05;
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;
void fragment() {
    // Get direction from center
    vec2 centered_uv = UV - vec2(0.5);
    float dist = length(centered_uv);
    vec2 direction = normalize(centered_uv);
    
    // Push pixels outward based on the ring texture
    float mask = texture(TEXTURE, UV).a;
    vec2 distorted_screen_uv = SCREEN_UV + direction * mask * distortion_strength;
    
    // Sample what's behind using the distorted coordinates
    vec3 background = texture(SCREEN_TEXTURE, distorted_screen_uv).rgb;
    
	
    // Show the distorted background
    COLOR.rgb = mix(background, vec3(1.0), mask * 0.01); // 0.01 = tint strength
    COLOR.a = mask;
}