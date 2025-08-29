extends Node

signal TilemapBoundsChanged ( bounds : Array [ Vector2 ] )
signal level_load_started
signal level_loaded

var current_tilemap_bounds : Array [ Vector2 ]
var target_transition : String
# --- NEW ---
# Add a variable to hold a reference to the main tilemap for ground sounds.
var main_tilemap : TileMapLayer
# --- END NEW ---


func _ready() -> void:
	await get_tree().process_frame
	level_loaded.emit()
	
func load_new_level( 
		level_path : String, 
		_target_transition : String
	 ) -> void:
	
	get_tree().paused = true
	target_transition = _target_transition
	
	# --- NEW ---
	# Clear the tilemap reference when changing levels.
	main_tilemap = null
	# --- END NEW ---
	
	PlayerManager.unparent_player()
	
	await SceneTransition.fade_out()
	
	level_load_started.emit()
	
	get_tree().change_scene_to_file( level_path )
	
	await SceneTransition.fade_in()
	
	get_tree().paused = false 
	
	await get_tree().process_frame
	
	level_loaded.emit()
	

func ChangeTilemapBounds ( bounds : Array [ Vector2 ] ) -> void:
	current_tilemap_bounds = bounds
	TilemapBoundsChanged.emit( bounds )
