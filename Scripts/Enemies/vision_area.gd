class_name VisionArea extends Area2D

signal player_entered()
signal player_exited()

func _ready() -> void:
	# Connect to signals for detecting the player.
	body_entered.connect( _on_body_enter )
	body_exited.connect( _on_body_exit )
	
	# We get the parent's parent because the VisionArea is under an "Interactions" node.
	var p = get_parent().get_parent()
	if p is Enemy:
		# Connect to the enemy's direction changed signal to update rotation.
		p.direction_changed.connect( _on_direction_changed )


func _on_body_enter( _b : Node2D ) -> void:
	# If the body that entered is the player, emit the corresponding signal.
	if _b is Player:
		player_entered.emit()

func _on_body_exit( _b : Node2D ) -> void:
	# If the body that exited is the player, emit the corresponding signal.
	if _b is Player:
		player_exited.emit()
	
func _on_direction_changed( new_direction : Vector2 ) -> void:
	# This is the corrected rotation logic.
	# It sets the rotation based on the angle of the new direction vector.
	# The default rotation (0) points down, so we don't need any complex offsets.
	# We simply use the angle of the vector directly.
	rotation = new_direction.angle() - (PI / 2)
