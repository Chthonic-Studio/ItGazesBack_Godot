class_name InteractionPrompt extends Node2D

@onready var label: Label = $Label

func _ready() -> void:
	hide()

## Sets the text of the prompt.
func set_text(text: String) -> void:
	label.text = text

## Shows the prompt.
func show_prompt() -> void:
	show()

## Hides the prompt.
func hide_prompt() -> void:
	hide()
