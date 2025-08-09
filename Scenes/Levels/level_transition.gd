@tool
class_name LevelTransition extends Area2D

# This enum is no longer needed with the new spawn point system.
# We comment it out to disable it, but you can remove it completely.
# enum SIDE { LEFT, RIGHT, TOP, BOTTOM }

## The .tscn of the level it transitions to
@export_file( "*.tscn" ) var level
## The name of the LevelTransition it transitions to in the target level
@export var target_transition_area : String = "LevelTransition"

@export_category("Collision Area Settings")

@export_range(1,12,1, "or_greater") var size : int = 2 : 
	set( _v ):
		size = _v
		_update_area()

# --- REASON FOR CHANGE ---
# The 'side' variable was used to calculate a spawn offset. Since we are now using a
# dedicated Marker2D for the spawn position, this logic is obsolete. We will keep
# the variable but hide it from the inspector to avoid confusion. Its logic in _update_area
# will be based on a simple horizontal/vertical orientation.
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
# --- REASON FOR CHANGE ---
# We add a reference to our new spawn location node.
@onready var spawn_location : Marker2D = $SpawnLocation

func _ready() -> void:
	_update_area()
	if Engine.is_editor_hint():
		return
	
	monitoring = false
	_place_player()
	
	await LevelManager.level_loaded
	
	monitoring = true
	body_entered.connect( _player_entered )
	
func _player_entered( _p : Node2D ) -> void:
	# --- REASON FOR CHANGE ---
	# We no longer need to calculate and pass a position offset. The destination
	# transition area will handle the spawning at its own Marker2D.
	LevelManager.load_new_level( level, target_transition_area )

func _place_player() -> void:
	if name != LevelManager.target_transition:
		return
	
	# --- REASON FOR CHANGE ---
	# This is the core of the new logic. Instead of using an offset from the LevelManager,
	# we now directly use the global position of our child SpawnLocation node.
	# This ensures the player spawns exactly where you place the marker in the editor.
	if not spawn_location:
		push_warning("LevelTransition is missing a SpawnLocation child node!")
		return
		
	PlayerManager.set_player_position( spawn_location.global_position )

# --- REASON FOR CHANGE ---
# This function is now obsolete and can be removed.
#func get_offset() -> Vector2:
#	var offset : Vector2 = Vector2.ZERO
#	var player_pos = PlayerManager.player.global_position
#	
#	if side == SIDE.LEFT or SIDE.RIGHT:
#		offset.y = player_pos.y - global_position.y
#		offset.x = 16
#		if side == SIDE.LEFT:
#			offset.x *= -1
#	else:
#		offset.x = player_pos.x - global_position.x
#		offset.y = 16
#		if side == SIDE.TOP:
#			offset.y *= -1
#	
#	return offset

func _update_area() -> void:
	var new_rect : Vector2 = Vector2( 32, 32 )
	var new_position : Vector2 = Vector2.ZERO
	
	# --- REASON FOR CHANGE ---
	# We simplify this logic. Instead of four sides, we just check if the
	# transition area is vertical or horizontal.
	if is_vertical:
		new_rect.y *= size
		new_position.y += 16 * (size-1) # Center the shape based on size
	else: # Horizontal
		new_rect.x *= size
		new_position.x += 16 * (size-1) # Center the shape based on size
		
	if collision_shape == null:
		collision_shape = get_node("CollisionShape2D")
	
	collision_shape.shape.size = new_rect
	collision_shape.position = new_position

func _snap_to_grid() -> void:
	position.x = round( position.x / 16 ) * 16
	position.y = round( position.y / 16 ) * 16
