class_name HidingVent extends Interactable

# --- How to use ---
# This is a simple hiding spot. The player can enter it to become hidden,
# but there is no secondary action (like transitioning levels).

func _ready() -> void:
	# Call the parent's _ready() function to ensure the body_entered signal is connected.
	super()
	
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

# When the player interacts for the first time, they enter the hidden state.
func on_interact(player: Player) -> void:
	player.state_machine.change_state(player.state_machine.get_node("Hidden"))

# --- REASON FOR CHANGE ---
# When the player interacts while already hidden, we now call the new function
# on the player to exit the hidden state. This is the second action.
func on_hidden_interact(player: Player) -> void:
	player.exit_hidden_state()

# The prompt will say "Hide".
func get_prompt_text() -> String:
	return "Hide"
	
# The prompt will say "Exit".
func get_hidden_prompt_text() -> String:
	return "Exit"
