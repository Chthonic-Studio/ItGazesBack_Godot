shader_type canvas_item;

// --- Uniforms controlled by player_hud.gd ---
// How far the pixels shift during a glitch.
uniform float shake_power : hint_range(0.0, 0.2, 0.001) = 0.0;
// The chance a glitch will happen each frame.
uniform float shake_rate : hint_range( 0.0, 1.0, 0.01 ) = 0.0;
// The speed of the glitch effect timing.
uniform float shake_speed : hint_range(0.0, 20.0, 0.1) = 5.0;
// The vertical size of the glitch blocks.
uniform float shake_block_size : hint_range(0.0, 100.0, 0.1) = 30.0;
// How much the red and blue color channels separate.
uniform float shake_color_rate : hint_range( 0.0, 0.1, 0.001 ) = 0.0;

// A simple function to generate a pseudo-random number.
float random( float seed )
{
	return fract( 543.2543 * sin( dot( vec2( seed, seed ), vec2( 3525.46, -54.3415 ) ) ) );
}

void fragment( )
{
	// Decide if a glitch should happen in this frame based on shake_rate.
	float enable_shift = float( random( trunc( TIME * shake_speed ) ) < shake_rate );

	// Start with the normal UV.
	vec2 fixed_uv = UV;
	
	// Calculate a horizontal offset for the glitch.
	// This uses the Y coordinate to create horizontal bars that shift independently.
	float x_offset = (
		random( ( trunc( UV.y * shake_block_size ) / shake_block_size ) + TIME ) - 0.5
	) * shake_power * enable_shift;
	fixed_uv.x += x_offset;

	// Get the pixel color from the shifted UV coordinate.
	vec4 pixel_color = texture( TEXTURE, fixed_uv );
	
	// If glitching, shift the red and blue channels slightly for a chromatic aberration effect.
	pixel_color.r = mix(
		pixel_color.r,
		texture( TEXTURE, fixed_uv + vec2( shake_color_rate, 0.0 ) ).r,
		enable_shift
	);
	pixel_color.b = mix(
		pixel_color.b,
		texture( TEXTURE, fixed_uv + vec2( -shake_color_rate, 0.0 ) ).b,
		enable_shift
	);
	
	// Keep original alpha, but apply the glitched RGB color.
	COLOR = vec4(pixel_color.rgb, texture(TEXTURE, UV).a);
}