class_name HidingVent extends Interactable

# --- How to use ---
# This is a simple hiding spot. The player can enter it to become hidden,
# but there is no secondary action (like transitioning levels).

func _ready() -> void:
	# Connect to the base class signals.
	player_entered.connect(_on_player_entered)
	player_exited.connect(_on_player_exited)

func _on_player_entered(interactable: Interactable) -> void:
	var player = PlayerManager.player
	if player:
		player.on_interactable_entered(self)

func _on_player_exited(interactable: Interactable) -> void:
	var player = PlayerManager.player
	if player:
		player.on_interactable_exited(self)

# When the player interacts, they enter the hidden state.
func on_interact(player: Player) -> void:
	player.state_machine.change_state(player.state_machine.get_node("Hidden"))

# The prompt will say "Hide".
func get_prompt_text() -> String:
	return "Hide"
