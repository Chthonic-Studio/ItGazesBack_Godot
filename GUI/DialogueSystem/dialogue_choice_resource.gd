class_name DialogueChoiceResource extends Resource
## Defines a single choice the player can make.

@export var text: String # The text displayed for the choice.
@export var next_node: DialogueNodeResource # The dialogue node to go to if this choice is selected.
@export var choice_id: String # An optional ID for scripts to react to this choice.
