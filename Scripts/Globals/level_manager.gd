extends Node

signal TilemapBoundsChanged ( bounds : Array [ Vector2 ] )
signal level_load_started
signal level_loaded

var current_tilemap_bounds : Array [ Vector2 ]
var target_transition : String


func _ready() -> void:
	await get_tree().process_frame
	level_loaded.emit()
	
func load_new_level( 
		level_path : String, 
		_target_transition : String
	 ) -> void:
	
	get_tree().paused = true
	target_transition = _target_transition
	
	# --- REASON FOR CHANGE ---
	# This line has been REMOVED. Resetting the state here was incorrect because
	# it happened before the new level could apply its own rules. The Level script
	# will now handle this logic correctly.
	# if PlayerManager.player:
	# 	PlayerManager.player.can_stand_up = true
	
	# We must unparent the player BEFORE the scene change to keep the instance alive.
	PlayerManager.unparent_player()
	
	await SceneTransition.fade_out()
	
	level_load_started.emit()
	
	# Change the scene. The old level is freed, but the player node (held by PlayerManager) persists.
	get_tree().change_scene_to_file( level_path )
	
	# Now that the new scene is loaded, wait for the fade-in to complete.
	await SceneTransition.fade_in()
	
	get_tree().paused = false 
	
	await get_tree().process_frame
	
	# The level_loaded signal will now be emitted by the new level itself,
	# ensuring the player is parented at the correct time.
	level_loaded.emit()
	

func ChangeTilemapBounds ( bounds : Array [ Vector2 ] ) -> void:
	current_tilemap_bounds = bounds
	TilemapBoundsChanged.emit( bounds )
