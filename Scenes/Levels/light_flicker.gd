extends PointLight2D

var flicker_timer : float = 0.135

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	flicker()


func flicker() -> void:
	energy = randf() * 0.1 + 0.9
	scale = Vector2( 1, 1 ) * energy
	await get_tree().create_timer( flicker_timer )
	flicker()
