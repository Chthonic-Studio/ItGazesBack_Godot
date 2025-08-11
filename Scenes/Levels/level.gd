class_name Level extends Node2D

@export var force_crouch : bool = false

func _ready() -> void:
	self.y_sort_enabled = true
	PlayerManager.set_as_parent( self )
	
	if force_crouch:
		# We wait a frame to ensure the player node is ready.
		await get_tree().process_frame
		PlayerManager.player.set_forced_crouch(true)

func _on_tree_exiting():
	# When leaving a level that forces crouch, we must re-enable standing.
	# Otherwise, the player would get stuck crouching in the next level.
	if force_crouch:
		PlayerManager.player.set_forced_crouch(false)
