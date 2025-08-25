class_name EnemyStatePatrol extends EnemyState

@export_category("Patrol Settings")
@export var move_speed: float = 20.0
@export var patrol_idle_duration: float = 3.0 # The base time to wait at each point.
@export var patrol_idle_randomness: float = 0.5 # 0 = no randomness, 1 = high randomness.
@export var anim_name: String = "walk"

var _current_target_index: int = 0
var _wait_timer: float = 0.0

func enter() -> void:
	if not enemy.patrol_path:
		print("ERROR: Patroller has no Path2D assigned!")
		return

	# Find the closest point on the path to start from.
	var path_points = enemy.patrol_path.curve.get_baked_points()
	if path_points.is_empty():
		return

	var closest_dist_sq = -1.0
	for i in range(path_points.size()):
		var dist_sq = enemy.global_position.distance_squared_to(enemy.patrol_path.global_position + path_points[i])
		if closest_dist_sq < 0 or dist_sq < closest_dist_sq:
			closest_dist_sq = dist_sq
			_current_target_index = i
	
	_set_wait_timer() # Start waiting immediately at the first point.
	enemy.update_animation("idle") # Start by being idle.

func process(delta: float) -> EnemyState:
	if _wait_timer > 0:
		_wait_timer -= delta
		if _wait_timer <= 0:
			# Finished waiting, move to the next point.
			_current_target_index = (_current_target_index + 1) % enemy.patrol_path.curve.get_point_count()
			enemy.update_animation(anim_name)
		return null

	var target_position = enemy.patrol_path.global_position + enemy.patrol_path.curve.get_point_position(_current_target_index)
	
	if enemy.global_position.distance_to(target_position) < 1.0:
		# Arrived at the point, start waiting.
		_set_wait_timer()
		enemy.update_animation("idle")
		enemy.velocity = Vector2.ZERO
	else:
		# Move towards the target.
		var direction = enemy.global_position.direction_to(target_position)
		enemy.velocity = direction * move_speed
		if enemy.set_direction(direction):
			enemy.update_animation(anim_name)
			
	return null

func _set_wait_timer() -> void:
	var randomness_factor = randf_range(1.0 - patrol_idle_randomness, 1.0 + patrol_idle_randomness)
	_wait_timer = patrol_idle_duration * randomness_factor
