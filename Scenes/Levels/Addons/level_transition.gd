@tool
class_name LevelTransition extends Interactable

@export_file( "*.tscn" ) var level
@export var target_transition_area : String = "LevelTransition"
@export var is_hiding_spot : bool = false

@export_category("Collision Area Settings")
# ... (size, is_vertical, snap_to_grid exports are unchanged) ...
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
	player_entered.connect(_on_player_entered)
	player_exited.connect(_on_player_exited)
	_update_area()
	if Engine.is_editor_hint():
		return
	_place_player()
	
func _on_player_entered(interactable: Interactable) -> void:
	var player = PlayerManager.player
	if player:
		player.on_interactable_entered(self)

func _on_player_exited(interactable: Interactable) -> void:
	var player = PlayerManager.player
	if player:
		player.on_interactable_exited(self)

func on_interact(player: Player) -> void:
	if is_hiding_spot:
		player.state_machine.change_state(player.state_machine.get_node("Hidden"))
	else:
		_transition_level()

func on_hidden_interact(player: Player) -> void:
	# --- REASON FOR CHANGE ---
	# Before transitioning, we set the flag in the PlayerManager.
	# This tells the system to spawn the player in the hidden state in the next level.
	if is_hiding_spot:
		PlayerManager.spawn_hidden = true
	_transition_level()

func get_hidden_prompt_text() -> String:
	if is_hiding_spot:
		return "Go In"
	return ""

func _transition_level():
	LevelManager.load_new_level( level, target_transition_area )

func _place_player() -> void:
	if name != LevelManager.target_transition:
		return
	
	if not spawn_location:
		push_warning("LevelTransition is missing a SpawnLocation child node!")
		return
	
	var player = PlayerManager.player
	# --- REASON FOR CHANGE ---
	# We now set the player's position directly here.
	player.global_position = spawn_location.global_position
	
	# After positioning the player, check if they should spawn hidden.
	if PlayerManager.spawn_hidden:
		# Tell the player to enter the hidden state inside THIS interactable.
		player.enter_hidden_state_on_spawn(self)
		# Reset the flag so it doesn't persist for the next transition.
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
