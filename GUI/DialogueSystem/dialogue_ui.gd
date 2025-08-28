class_name DialogueUI extends CanvasLayer

signal advance_request
signal choice_selected(choice: DialogueChoiceResource)
signal exit_request

@onready var speaker_label: Label = $Panel/SpeakerLabel
@onready var dialogue_label: Label = $Panel/MarginContainer/VBoxContainer/DialogueLabel
@onready var choices_box: VBoxContainer = $Panel/MarginContainer/VBoxContainer/ChoicesBox
@onready var advance_indicator: Label = $Panel/AdvanceIndicator

# This function is called by DialogueManager to display a dialogue node.
func show_node(node: DialogueNodeResource) -> void:
	# Clear previous choices
	for child in choices_box.get_children():
		child.queue_free()

	speaker_label.text = node.speaker
	dialogue_label.text = node.text
	
	# Handle node type specific display
	match node.type:
		DialogueNodeResource.NodeType.LINE:
			speaker_label.show()
		DialogueNodeResource.NodeType.LORE:
			speaker_label.hide() # Lore datapads don't have a speaker

	if not node.choices.is_empty():
		advance_indicator.hide()
		# Create buttons for each choice
		for choice_res in node.choices:
			var button = Button.new()
			button.text = choice_res.text
			button.pressed.connect(_on_choice_button_pressed.bind(choice_res))
			choices_box.add_child(button)
	else:
		advance_indicator.show()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		exit_request.emit()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("interact"):
		advance_request.emit()
		get_viewport().set_input_as_handled()

# When a choice button is pressed, emit the signal with the corresponding resource.
func _on_choice_button_pressed(choice_res: DialogueChoiceResource) -> void:
	choice_selected.emit(choice_res)
