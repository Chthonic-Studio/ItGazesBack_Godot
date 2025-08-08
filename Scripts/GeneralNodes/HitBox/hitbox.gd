class_name HitBox extends Area2D

signal damaged ( damage : int )

func _ready() -> void:
	pass # Replace with function body.


func _process(delta: float) -> void:
	pass

func take_damage( damage : int ) -> void:
	print( "Damage Taken: ", damage )
	damaged.emit( damage )
