class_name EnemyStateSearch extends EnemyState

@export_category("Search Timings")
@export var idle_duration: float = 3.0
@export var idle_randomness: float = 0.5
@export var search_duration: float = 5.0 # How long to wander/search for.
@export var search_randomness: float = 0.5

@export_category("Dependencies")
@export var patrol_state: EnemyStatePatrol
@export var idle_state: EnemyStateIdle

enum SearchPhase { IDLE, WANDERING }
var _current_phase: SearchPhase
var _timer: float

func enter() -> void:
	# Start in the IDLE phase.
	_current_phase = SearchPhase.IDLE
	var randomness = randf_range(1.0 - idle_randomness, 1.0 + idle_randomness)
	_timer = idle_duration * randomness
	enemy.update_animation("idle")
	enemy.velocity = Vector2.ZERO

func process(delta: float) -> EnemyState:
	_timer -= delta
	if _timer <= 0:
		return _transition_to_next_phase()
	return null

func _transition_to_next_phase() -> EnemyState:
	match _current_phase:
		SearchPhase.IDLE:
			# Finished idling, now start wandering.
			_current_phase = SearchPhase.WANDERING
			var randomness = randf_range(1.0 - search_randomness, 1.0 + search_randomness)
			_timer = search_duration * randomness
			# Use the wander logic to move around.
			var rand_dir = enemy.DIR_4[randi_range(0, 3)]
			enemy.set_direction(rand_dir)
			enemy.velocity = rand_dir * 20.0 # Using a fixed wander speed.
			enemy.update_animation("walk")
			return null # Stay in this state.
			
		SearchPhase.WANDERING:
			# Finished wandering, return to the patrol state.
			if patrol_state:
				return patrol_state
			# Fallback to idle if no patrol state is assigned (for Roamers).
			return idle_state
	return null # Should not be reached.
