class_name LevelGeometry extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Wait until all children nodes are ready before calculating the bounds.
	await get_tree().process_frame
	
	var combined_rect := Rect2()
	var first_tilemap : bool = true
	
	# Iterate through all children to find TileMapLayers.
	for node in get_children():
		if node is TileMapLayer:
			var tilemap : TileMapLayer = node
			var used_rect : Rect2i = tilemap.get_used_rect()
			
			# --- NEW ---
			# If this tilemap is our main ground layer, register it with the LevelManager.
			if tilemap.name == "GroundTiles":
				LevelManager.main_tilemap = tilemap
			# --- END NEW ---
			
			# The rect is in tile coordinates, so we convert it to global world coordinates.
			var world_rect : Rect2 = Rect2(
				tilemap.map_to_local(used_rect.position),
				tilemap.map_to_local(used_rect.size)
			)
			
			if first_tilemap:
				combined_rect = world_rect
				first_tilemap = false
			else:
				# The 'merge' function expands the rect to include the new one.
				combined_rect = combined_rect.merge(world_rect)
	
	# If we found at least one tilemap, update the LevelManager.
	if not first_tilemap:
		var bounds : Array[Vector2] = [
			combined_rect.position,
			combined_rect.end
		]
		LevelManager.ChangeTilemapBounds(bounds)
