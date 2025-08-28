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
	print("DEBUG: Interactable '", name, "' is ready.")


func _on_body_entered(body: Node2D) -> void:
	print("DEBUG: Interactable '", name, "' detected body: ", body.name)
	
	if body is Player:
		if animated_sprite and animated_sprite.sprite_frames.has_animation("Open"):
			animated_sprite.play("Open")
		player_entered.emit(self)

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		if animated_sprite and animated_sprite.sprite_frames.has_animation("Close"):
			animated_sprite.play("Close")
		player_exited.emit(self)

func on_interact(player: Player) -> void:
	# --- REASON FOR CHANGE ---
	# We now check if a dialogue tree has been assigned. If so, we emit a signal
	# to the DialogueManager to start it. If not, we fall back to the old behavior.
	# This makes the change fully backward-compatible.
	if dialogue_tree:
		DialogueManager.start_dialogue_request.emit(dialogue_tree)
	else:
		# Fallback for interactables that don't use the dialogue system.
		print("Interaction with: ", name)
	# --------------------------
	pass

func on_hidden_interact(player: Player) -> void:
	on_interact(player)

func get_prompt_text() -> String:
	# --- REASON FOR CHANGE ---
	# If a dialogue tree is present, the prompt should be more specific.
	if dialogue_tree:
		return "Read" # Or "Talk", "Inspect", etc.
	# --------------------------
	return "Enter"

func get_hidden_prompt_text() -> String:
	return ""
