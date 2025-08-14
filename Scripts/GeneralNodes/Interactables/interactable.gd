class_name Interactable extends Area2D

@export_category("Animation")
## Optional: An AnimatedSprite2D to play animations on player enter/exit.
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

signal player_entered(interactable: Interactable)
signal player_exited(interactable: Interactable)

func _ready() -> void:
	# Connect the Area2D signals to our own functions.
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	# This lets us know the interactable is in the scene and ready.
	print("DEBUG: Interactable '", name, "' is ready.")


func _on_body_entered(body: Node2D) -> void:
	# --- REASON FOR CHANGE ---
	# This is our most important debug print. It will tell us if the Area2D is detecting
	# a collision with ANY physics body. If this print does not appear, the core problem
	# is with the physics engine's collision detection.
	print("DEBUG: Interactable '", name, "' detected body: ", body.name)
	
	if body is Player:
		# --- NEW ---
		# If an animated sprite is assigned and has an "Open" animation, play it.
		if animated_sprite and animated_sprite.sprite_frames.has_animation("Open"):
			animated_sprite.play("Open")
		# --- END NEW ---
		player_entered.emit(self)

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		# --- NEW ---
		# If an animated sprite is assigned and has a "Close" animation, play it.
		if animated_sprite and animated_sprite.sprite_frames.has_animation("Close"):
			animated_sprite.play("Close")
		# --- END NEW ---
		player_exited.emit(self)

## This function is called by the Player when the 'interact' key is pressed.
## It should be overridden by child classes (like LevelTransition).
func on_interact(player: Player) -> void:
	print("Interaction with: ", name)
	pass

## This function is called when the player is in the 'Hidden' state inside this interactable.
## It can be used to change the prompt (e.g., from "Enter" to "Go In").
func on_hidden_interact(player: Player) -> void:
	# By default, do the same as a normal interaction.
	on_interact(player)

## The text to show when the player is nearby. Override in child classes.
func get_prompt_text() -> String:
	return "Enter"

## The text to show when the player is hidden inside this interactable.
func get_hidden_prompt_text() -> String:
	# By default, there is no prompt while hidden.
	return ""
