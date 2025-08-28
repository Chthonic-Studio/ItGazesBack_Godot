class_name DialogueNodeResource extends Resource
## Defines one "beat" in a conversation. It can be a line of dialogue or a block of lore.

enum NodeType { LINE, LORE }

@export var type: NodeType = NodeType.LINE

@export_group("Line Settings", "type_")
@export var speaker: String # The name of the character speaking.
@export_multiline var text: String # The dialogue text itself.
@export var voice_line: AudioStream # Placeholder for a voice-over.

@export_group("Branching")
## If 'choices' is empty, this will be the next node automatically.
@export var next_node: DialogueNodeResource
## If this array is not empty, the player will be presented with these choices.
@export var choices: Array[DialogueChoiceResource]
