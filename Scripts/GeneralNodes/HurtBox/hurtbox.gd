class_name HurtBox extends Area2D

@export var damage : int = 1

func _ready() -> void:
	area_entered.connect( AreaEntered )

func _process(delta: float) -> void:
	pass

func AreaEntered( a : Area2D ) -> void:
	if a is HitBox:
		# We now pass 'self' so the HitBox knows which HurtBox hit it.
		a.take_damage( damage, self )
	pass
