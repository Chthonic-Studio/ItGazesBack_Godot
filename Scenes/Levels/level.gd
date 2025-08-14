class_name Level extends Node2D

@export var force_crouch : bool = false

func _ready() -> void:
	self.y_sort_enabled = true
	
	PlayerManager.level_forces_crouch = force_crouch
	
	if PlayerManager.player:
		PlayerManager.set_as_parent( self )
