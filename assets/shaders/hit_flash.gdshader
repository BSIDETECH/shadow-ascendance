shader_type canvas_item;

// Instance uniform allows each entity to flash independently without breaking draw-call batching
instance uniform float flash_modifier : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	vec3 flashed_rgb = mix(tex_color.rgb, flash_color.rgb, flash_modifier);
	COLOR = vec4(flashed_rgb, tex_color.a);
}
