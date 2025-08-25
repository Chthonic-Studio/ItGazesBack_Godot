class_name Pathfinder extends Node2D

var vectors: Array [ Vector2 ] = [
	Vector2(0, -1), #UP
	Vector2(1, -1), #UP_RIGHT
	Vector2(1, 0), #RIGHT
	Vector2(1, 1), #DOWN_RIGHT
	Vector2(0, 1), #DOWN
	Vector2(-1, 1), #ODWN_LEFT
	Vector2(-1, 0), #LEFT
	Vector2(-1, -1), #UP_LEFT
]
var interests: Array [ float ]
var obstacles : Array [ float ] = [ 0, 0, 0, 0, 0, 0, 0, 0 ]
var outcomes : Array [ float ] = [ 0, 0, 0, 0, 0, 0, 0, 0 ]
var rays : Array [ RayCast2D ]

var move_dir : Vector2 = Vector2.ZERO
var best_path : Vector2 = Vector2.ZERO

@onready var timer: Timer = $Timer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Gather all Raycast2D nodes
	for c in get_children():
		if c is RayCast2D:
			rays.append( c )
	
	# Normalized all vectors		
	for v in vectors:
		v = v.normalized()
	for i in vectors.size():
		vectors[ i ] = vectors[ i ].normalized()
	
	# Perform initial pathfinder function
	set_path()
	
	
	
	timer.timeout.connect( set_path )


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	move_dir = lerp( move_dir, best_path, 10 * delta )

# Set the best path that the entity wants to follow by checking for desired direction
# and considering obstacles 
func set_path() -> void:
	# Get direction to the player
	var player_dir : Vector2 = global_position.direction_to( PlayerManager.player.global_position )
	
	# Reset obstacles values to 0
	for i in 8:
		obstacles [ i ] = 0
		outcomes [ i ] = 0
	
	# Check each Raycast2D for collision & update values in obstacles array
	for i in 8:
		if rays [ i ].is_colliding():
			obstacles[ i ] += 4
			obstacles[ get_next_i( i ) ] += 1
			obstacles[ get_prev_i( i ) ] += 1
	
	# If there are no obstacles, recommend path in direction to player
	if obstacles.max() == 0:
		best_path = player_dir
		return
	
	# Populate interest array. This contains the values that represent the desireability of each direction
	interests.clear()
	for v in vectors:
		interests.append( v.dot( player_dir ) )
		
	# Populate outcomes array by comining interest with obstacles
	for i in 8:
		outcomes [ i ] = interests [ i ] - obstacles [ i ]
	
	print( "Outcomes: ", outcomes)
	print( "Interests: ", interests)
	print( "Outcomes: ", interests)
	# Set the best path with Vector2 that corresponds with the outcome of the best value
	
	best_path = vectors [ outcomes.find( outcomes.max() ) ]
	
	
func get_next_i ( i : int) -> int:
	var n_i : int = i + 1
	if n_i >= 8:
		return 0
	else:
		return n_i

func get_prev_i ( i : int) -> int:
	var n_i : int = i - 1
	if n_i < 0:
		return 7
	else:
		return n_i
