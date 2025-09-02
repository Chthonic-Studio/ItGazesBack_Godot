// This shader creates a field-of-view cone effect.
// It darkens the whole screen except for a cone originating from the player's world position,
// pointing towards the mouse cursor. All calculations are done in world space for accuracy.

shader_type canvas_item;

// The color of the darkness/obscurity that covers the screen.
uniform vec4 obscurity_color : source_color = vec4(0.0, 0.0, 0.0, 0.8);

// --- UNIFORMS FOR WORLD SPACE CALCULATIONS ---
uniform vec2 player_world_pos;
uniform vec2 cone_direction;
uniform vec2 camera_pos;
uniform vec2 viewport_size;
uniform vec2 camera_zoom;

// --- CONE GEOMETRY SETTINGS ---
uniform float fov_angle = 45.0;
uniform float fov_distance = 400.0;
uniform float edge_softness = 0.05;


void fragment() {
	// Reconstruct the world position of the current pixel from its SCREEN_UV.
	vec2 world_origin = camera_pos - (viewport_size * camera_zoom / 2.0);
	vec2 world_offset = SCREEN_UV * viewport_size * camera_zoom;
	vec2 world_pos = world_origin + world_offset;

	vec2 to_pixel_world = world_pos - player_world_pos;
	float dist = length(to_pixel_world);
	
	// --- REASON FOR CHANGE ---
	// The shader logic is now structured as an if/else if/else block.
	// This avoids the illegal 'return' statement and ensures the COLOR variable is always set once at the end of the function's execution path.
	if (dist < 0.1) {
		// Case 1: The pixel is at the very center (on the player). Make it fully transparent.
		COLOR = vec4(obscurity_color.rgb, 0.0);
	} else {
		float fov_rad = radians(fov_angle);
		float dot_product = dot(normalize(to_pixel_world), cone_direction);
		float angle = acos(dot_product);
		
		if (dist < fov_distance && angle < fov_rad) {
			// Case 2: The pixel is inside the vision cone. Calculate its transparency.
			float distance_alpha = 1.0 - smoothstep(fov_distance - (fov_distance * edge_softness), fov_distance, dist);
			float angle_alpha = 1.0 - smoothstep(fov_rad - (fov_rad * edge_softness), fov_rad, angle);
			
			// "Cut out" the cone shape from the obscurity color.
			COLOR = vec4(obscurity_color.rgb, obscurity_color.a * (1.0 - min(distance_alpha, angle_alpha)));
		} else {
			// Case 3: The pixel is outside the cone. It's fully obscured.
			COLOR = obscurity_color;
		}
	}
}