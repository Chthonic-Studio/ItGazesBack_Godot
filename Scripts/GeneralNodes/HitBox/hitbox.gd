class_name HitBox extends Area2D

# The signal now also emits the HurtBox that caused the damage.
signal damaged ( damage : int, hurtbox : HurtBox )

func _ready() -> void:
	pass # Replace with function body.


func _process(delta: float) -> void:
	pass

# The function now accepts the hurtbox as an argument.
func take_damage( damage : int, hurtbox : HurtBox ) -> void:
	print( "Damage Taken: ", damage )
	# We emit the hurtbox along with the damage amount.
	damaged.emit( damage, hurtbox )
