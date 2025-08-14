class_name State_Hidden extends State

@onready var idle: State = $"../Idle"
@onready var crouch: State = $"../Crouch"

func enter() -> void:
	# Use the new player function to hide sprite and disable collision.
	player.set_hidden_state(true)
	# Stop all movement.
	player.velocity = Vector2.ZERO
	# Update the prompt text (e.g. from "Enter" to "Go In").
	player.update_hidden_prompt()

func exit() -> void:
	# Unhide the player and re-enable collision.
	player.set_hidden_state(false)
	# Hide the prompt when leaving the hidden state.
	player._interaction_prompt.hide_prompt()

func process(_delta: float) -> State:
	# If the player moves, they exit the hidden state.
	if player.direction != Vector2.ZERO:
		# If the player was crouched before hiding, we return them to the Crouch state.
		# Otherwise, we return them to the Idle state as before.
		if PlayerManager.is_crouched:
			return crouch
		else:
			return idle
		
	return null
