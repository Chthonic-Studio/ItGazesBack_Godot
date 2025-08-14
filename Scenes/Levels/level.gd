class_name Level extends Node2D

@export var force_crouch : bool = false

func _ready() -> void:
	self.y_sort_enabled = true
	
	# 1. Set global constraint flag.
	PlayerManager.level_forces_crouch = force_crouch
	
	# 2. Reparent the persistent player into this level.
	if PlayerManager.player:
		PlayerManager.set_as_parent(self)
		
		# 3. Enforce or release crouch constraint immediately.
		if force_crouch:
			# Force crouch & lock standing
			PlayerManager.player.can_stand_up = false
			# If player currently not in Crouch state, push them in.
			if not PlayerManager.player.is_crouched:
				PlayerManager.player.state_machine.change_state(
					PlayerManager.player.state_machine.get_node("Crouch")
				)
			PlayerManager.player.is_crouched = true	# Ensures memory flag set via setter
			PlayerManager.is_crouched = true			# Redundant but explicit
		else:
			# Release lock; keep sticky crouch memory if they were crouched.
			PlayerManager.player.can_stand_up = true
			# Do NOT auto-stand; design says they stay crouched until manual toggle.
