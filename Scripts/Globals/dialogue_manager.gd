extends Node

signal dialogue_started
signal dialogue_ended
signal choice_made(choice_id: String)
signal start_dialogue_request(tree: DialogueTreeResource)

const DIALOGUE_UI_SCENE = preload("res://GUI/DialogueSystem/dialogue_ui.tscn")

var dialogue_ui: CanvasLayer
var current_tree: DialogueTreeResource
var current_node: DialogueNodeResource
var is_dialogue_active: bool = false

func _ready() -> void:
	# Connect the signal to the internal function. This allows any node to request a dialogue.
	start_dialogue_request.connect(start_dialogue)

# --- Public API ---

# This function begins a dialogue sequence.
func start_dialogue(tree: DialogueTreeResource) -> void:
	if is_dialogue_active or not tree or not tree.root_node:
		return

	# Pause the game to focus the player on the conversation.
	get_tree().paused = true
	is_dialogue_active = true

	# Create and display the UI.
	dialogue_ui = DIALOGUE_UI_SCENE.instantiate()
	get_tree().root.add_child(dialogue_ui)
	dialogue_ui.process_mode = Node.PROCESS_MODE_WHEN_PAUSED # Ensure UI runs while game is paused.

	# Connect to the UI signals that will drive the conversation forward.
	dialogue_ui.advance_request.connect(_on_advance_request)
	dialogue_ui.choice_selected.connect(_on_choice_selected)
	dialogue_ui.exit_request.connect(_end_dialogue)


	current_tree = tree
	current_node = tree.root_node
	_show_node(current_node)

	dialogue_started.emit()

# --- Private Logic ---

# Called when the player clicks to advance simple dialogue.
func _on_advance_request() -> void:
	if not is_dialogue_active or not current_node: return
	
	var has_next_node = is_instance_valid(current_node.next_node)
	var has_choices = not current_node.choices.is_empty()

	if has_next_node:
		# If there's a next node, we advance to it.
		current_node = current_node.next_node
		_show_node(current_node)
	elif not has_choices:
		# Only if there's NO next node and NO choices do we end the dialogue.
		_end_dialogue()

# Called when the player clicks a choice button in the UI.
func _on_choice_selected(choice: DialogueChoiceResource) -> void:
	if not is_dialogue_active: return

	# Emit a signal with the choice's ID so other systems can react.
	if not choice.choice_id.is_empty():
		choice_made.emit(choice.choice_id)

	# Move to the next node specified by the choice.
	if choice.next_node:
		current_node = choice.next_node
		_show_node(current_node)
	else:
		_end_dialogue()

# Central function to display the content of any given node.
func _show_node(node: DialogueNodeResource) -> void:
	dialogue_ui.show_node(node)
	# Here is where you would add logic to play the voice line, e.g.:
	# if node.voice_line:
	#     $VoicePlayer.stream = node.voice_line
	#     $VoicePlayer.play()

# Cleans up the dialogue UI and unpauses the game.
func _end_dialogue() -> void:
	if not is_dialogue_active: return

	is_dialogue_active = false
	if is_instance_valid(dialogue_ui):
		# Disconnect signals before freeing to prevent errors on rapid open/close.
		if dialogue_ui.exit_request.is_connected(_end_dialogue):
			dialogue_ui.exit_request.disconnect(_end_dialogue)
		if dialogue_ui.advance_request.is_connected(_on_advance_request):
			dialogue_ui.advance_request.disconnect(_on_advance_request)
		if dialogue_ui.choice_selected.is_connected(_on_choice_selected):
			dialogue_ui.choice_selected.disconnect(_on_choice_selected)
		
		dialogue_ui.queue_free()
	
	current_tree = null
	current_node = null
	
	if PlayerManager.player:
		PlayerManager.player._clear_interactable()
	# --------------------------
	
	get_tree().paused = false
	dialogue_ended.emit()
