@tool
class_name LevelTransition extends Interactable

@export_file( "*.tscn" ) var level
@export var target_transition_area : String = "LevelTransition"
@export var is_hiding_spot : bool = false

@export_category("Collision Area Settings")
@export_range(1,12,1, "or_greater") var size : int = 2 : 
	set( _v ):
		size = _v
		_update_area()
		
@export var is_vertical : bool = false :
	set( _v ):
		is_vertical = _v
		_update_area()
		
@export var snap_to_grid : bool = false:
	set( _v ):
		if _v == true:
			_snap_to_grid()
			snap_to_grid = false
			notify_property_list_changed()

@onready var collision_shape : CollisionShape2D = $CollisionShape2D
@onready var spawn_location : Marker2D = $SpawnLocation

func _ready() -> void:
	super()
	player_entered.connect(_on_player_entered)
	player_exited.connect(_on_player_exited)
	_update_area()
	if Engine.is_editor_hint():
		return
	# We now wait a frame to ensure the player is ready before placing them.
	await get_tree().process_frame
	_place_player()
	
func _on_player_entered(interactable: Interactable) -> void:
	var player = PlayerManager.player
	if player:
		player.on_interactable_entered(self)

func _on_player_exited(interactable: Interactable) -> void:
	var player = PlayerManager.player
	if player:
		player.on_interactable_exited(self)

# This function is called for the FIRST interaction.
func on_interact(player: Player) -> void:
	if is_hiding_spot:
		# If it's a hiding spot, the first action is to enter the Hidden state.
		player.state_machine.change_state(player.state_machine.get_node("Hidden"))
	else:
		# If it's not a hiding spot, we transition immediately.
		_transition_level()

# --- REASON FOR CHANGE ---
# This function is called when the player interacts WHILE ALREADY HIDDEN.
# This is our second action.
func on_hidden_interact(player: Player) -> void:
	# If it's a hiding spot, the second action is to transition.
	if is_hiding_spot:
		# We set the global flag to true BEFORE loading the new level.
		PlayerManager.spawn_hidden = true
	# Now, we transition.
	_transition_level()

# --- REASON FOR CHANGE ---
# This function provides the prompt text for when the player is hidden.
func get_hidden_prompt_text() -> String:
	if is_hiding_spot:
		# If we can transition from here, the prompt changes.
		return "Go inside"
	# If it's not a hiding spot, there's no action while hidden.
	return ""

func _transition_level():
	LevelManager.load_new_level( level, target_transition_area )

# This function places the player when a new level loads.
func _place_player() -> void:
	if name != LevelManager.target_transition:
		return
	
	if not spawn_location:
		push_warning("LevelTransition is missing a SpawnLocation child node!")
		return
	
	var player = PlayerManager.player
	player.global_position = spawn_location.global_position
	
	# --- REASON FOR CHANGE ---
	# After placing the player, we check the global flag.
	if PlayerManager.spawn_hidden:
		# If the flag is true, we call a new function on the player to force them
		# into the hidden state within this interactable.
		player.enter_hidden_state_on_spawn(self)
		# We must reset the flag so it doesn't affect future transitions.
		PlayerManager.spawn_hidden = false

func _update_area() -> void:
	var new_rect : Vector2 = Vector2( 32, 32 )
	var new_position : Vector2 = Vector2.ZERO
	
	if is_vertical:
		new_rect.y *= size
		new_position.y += 16 * (size-1)
	else:
		new_rect.x *= size
		new_position.x += 16 * (size-1)
		
	if collision_shape == null:
		collision_shape = get_node("CollisionShape2D")
	
	collision_shape.shape.size = new_rect
	collision_shape.position = new_position

func _snap_to_grid() -> void:
	position.x = round( position.x / 16 ) * 16
	position.y = round( position.y / 16 ) * 16
