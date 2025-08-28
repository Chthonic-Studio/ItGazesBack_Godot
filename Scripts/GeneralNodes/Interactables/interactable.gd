class_name Interactable extends Area2D

@export_category("Animation")
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export_category("Dialogue")
## If this resource is assigned, interacting will trigger a dialogue.
@export var dialogue_tree: DialogueTreeResource
# --------------------------

signal player_entered(interactable: Interactable)
signal player_exited(interactable: Interactable)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	player_entered.connect(_on_player_entered_handler)
	player_exited.connect(_on_player_exited_handler)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		if animated_sprite and animated_sprite.sprite_frames.has_animation("Open"):
			animated_sprite.play("Open")
		player_entered.emit(self)

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		if animated_sprite and animated_sprite.sprite_frames.has_animation("Close"):
			animated_sprite.play("Close")
		player_exited.emit(self)

# --- NEW FUNCTION ---
# This function now handles the core logic of telling the player an interactable is available.
# Child classes like HidingVent already have this logic, so this change won't break them.
# It fixes any interactable that uses the base script directly.
func _on_player_entered_handler(interactable: Interactable) -> void:
	if PlayerManager.player:
		PlayerManager.player.on_interactable_entered(self)

# --- NEW FUNCTION ---
# Similarly, this handles telling the player the interactable is no longer available.
func _on_player_exited_handler(interactable: Interactable) -> void:
	if PlayerManager.player:
		PlayerManager.player.on_interactable_exited(self)


func on_interact(player: Player) -> void:
	if dialogue_tree:
		# The DialogueManager pauses the game, so we emit the signal.
		DialogueManager.start_dialogue_request.emit(dialogue_tree)
	else:
		# Fallback for interactables that don't use the dialogue system.
		print("Interaction with: ", name)
	pass

func on_hidden_interact(player: Player) -> void:
	on_interact(player)

func get_prompt_text() -> String:
	if dialogue_tree:
		return "Read"
	return "Interact"

func get_hidden_prompt_text() -> String:
	return ""
