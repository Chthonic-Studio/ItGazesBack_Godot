extends Node

signal TilemapBoundsChanged ( bounds : Array [ Vector2 ] )
signal level_load_started
signal level_loaded

var current_tilemap_bounds : Array [ Vector2 ]
var target_transition : String
# --- REASON FOR CHANGE ---
# This variable is no longer needed, as the spawn position is now handled
# directly by the destination LevelTransition node.
# var position_offset : Vector2

func _ready() -> void:
	await get_tree().process_frame
	level_loaded.emit()
	
# --- REASON FOR CHANGE ---
# We remove the _position_offset parameter from the function signature.
func load_new_level( 
		level_path : String, 
		_target_transition : String
	 ) -> void:
	
	get_tree().paused = true
	target_transition = _target_transition
	# position_offset = _position_offset # This line is removed.
	
	await SceneTransition.fade_out()
	
	level_load_started.emit()
	
	await get_tree().process_frame
	
	PlayerManager.unparent_player()
	
	get_tree().change_scene_to_file( level_path )
	
	await SceneTransition.fade_in()
	
	get_tree().paused = false 
	
	await get_tree().process_frame
	
	level_loaded.emit()
	

func ChangeTilemapBounds ( bounds : Array [ Vector2 ] ) -> void:
	current_tilemap_bounds = bounds
	TilemapBoundsChanged.emit( bounds )
