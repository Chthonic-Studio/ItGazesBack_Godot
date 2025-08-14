class_name State_Hidden extends State

@onready var idle: State = $"../Idle"
@onready var crouch: State = $"../Crouch"

func enter() -> void:
	player.set_hidden_state(true)
	player.velocity = Vector2.ZERO
	player.update_hidden_prompt()

func exit() -> void:
	player.set_hidden_state(false)
	player._interaction_prompt.hide_prompt()

func process(_delta: float) -> State:
	if player.direction != Vector2.ZERO:
		# Restore posture if crouched memory or forced
		if PlayerManager.is_crouched or PlayerManager.level_forces_crouch:
			return crouch
		return idle
	return null
