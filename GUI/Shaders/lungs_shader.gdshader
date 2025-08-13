shader_type canvas_item;

// --- Uniforms controlled by player_hud.gd ---
// The speed of the breathing animation.
uniform float breathing_speed : hint_range(1.0, 20.0, 0.1) = 4.0;
// How much the sprite scales up and down.
uniform float scale_amount : hint_range(0.0, 0.5, 0.01) = 0.05;
// The intensity of the red tint (0.0 = no tint, 1.0 = fully red).
uniform float red_tint_intensity : hint_range(0.0, 1.0, 0.01) = 0.0;

// This function runs for every vertex of the sprite. We use it to modify the scale.
void vertex() {
	// Calculate a smooth wave between 0.0 and 1.0 using sine.
	float scale_factor = (sin(TIME * breathing_speed) + 1.0) / 2.0; 
	// Apply the scale. We scale the vertex position relative to the center of the object.
	// This creates a "breathing" effect by scaling the sprite up and down.
	VERTEX.xy *= 1.0 + (scale_factor * scale_amount);
}

// This function runs for every pixel of the sprite. We use it to change the color.
void fragment() {
	// Get the original color of the pixel from the sprite's texture.
	vec4 original_color = texture(TEXTURE, UV);
	// Define the red color we want to tint with.
	vec3 red_tint = vec3(1.0, 0.0, 0.0);
	
	// Mix the original color with the red tint based on the intensity.
	// If intensity is 0, color is original. If 1, it's fully red.
	original_color.rgb = mix(original_color.rgb, red_tint, red_tint_intensity);
	
	// Set the final pixel color.
	COLOR = original_color;
}