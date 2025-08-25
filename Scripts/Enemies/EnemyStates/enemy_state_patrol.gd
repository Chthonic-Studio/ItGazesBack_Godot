class_name EnemyStatePatrol extends EnemyState

@export_category("Patrol Settings")
@export var move_speed: float = 20.0
@export var patrol_idle_duration: float = 3.0 # The base time to wait at each point.
@export var patrol_idle_randomness: float = 0.5 # 0 = no randomness, 1 = high randomness.
@export var anim_name: String = "walk"

enum PatrolPhase { MOVING, WAITING }
var _current_phase: PatrolPhase

var _current_target_index: int = 0
var _wait_timer: float = 0.0

func enter() -> void:
	if not enemy.patrol_path or not enemy.patrol_path.curve:
		print("ERROR: Patroller '", enemy.name, "' has no Path2D or Curve assigned!")
		set_physics_process(false) # Disable physics process for this state
		return

	var point_count = enemy.patrol_path.curve.get_point_count()
	if point_count == 0:
		print("WARNING: Patrol path for '", enemy.name, "' has no points.")
		set_physics_process(false)
		return

	var closest_dist_sq = -1.0
	for i in range(point_count):
		var point_global_pos = enemy.patrol_path.global_position + enemy.patrol_path.curve.get_point_position(i)
		var dist_sq = enemy.global_position.distance_squared_to(point_global_pos)
		if closest_dist_sq < 0 or dist_sq < closest_dist_sq:
			closest_dist_sq = dist_sq
			_current_target_index = i
	
	_current_phase = PatrolPhase.MOVING
	enemy.update_animation(anim_name)

# --- REASON FOR CHANGE ---
# The process function is now ONLY responsible for handling the waiting timer.
# This keeps its logic clean and focused on time-based events, not movement.
func process(delta: float) -> EnemyState:
	if _current_phase == PatrolPhase.WAITING:
		_wait_timer -= delta
		if _wait_timer <= 0:
			_current_target_index = (_current_target_index + 1) % enemy.patrol_path.curve.get_point_count()
			_current_phase = PatrolPhase.MOVING
			enemy.update_animation(anim_name)
			
	return null

# --- REASON FOR CHANGE ---
# All movement logic has been moved to the physics() function. This is the correct
# place for it, as it ensures the velocity is calculated and applied in the same
# physics frame, resulting in smooth and reliable movement.
func physics(_delta: float) -> EnemyState:
	if _current_phase == PatrolPhase.MOVING:
		var target_position = enemy.patrol_path.global_position + enemy.patrol_path.curve.get_point_position(_current_target_index)
		
		if enemy.global_position.distance_to(target_position) < 2.0:
			# Arrived at the point, switch to waiting.
			_current_phase = PatrolPhase.WAITING
			_set_wait_timer()
			enemy.update_animation("idle")
			enemy.velocity = Vector2.ZERO
		else:
			# Still moving, update velocity.
			var direction = enemy.global_position.direction_to(target_position)
			enemy.velocity = direction * move_speed
			if enemy.set_direction(direction):
				enemy.update_animation(anim_name)
	
	return null

func _set_wait_timer() -> void:
	var randomness_factor = randf_range(1.0 - patrol_idle_randomness, 1.0 + patrol_idle_randomness)
	_wait_timer = patrol_idle_duration * randomness_factor
