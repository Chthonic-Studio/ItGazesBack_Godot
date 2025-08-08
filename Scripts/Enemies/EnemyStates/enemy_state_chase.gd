class_name EnemyStateChase extends EnemyState

@export var anim_name : String = "walk" # Using "walk" as the animation for chasing.
@export var chase_speed : float = 40.0
@export var turn_rate : float = 0.25

@export_category("AI")
@export var state_aggro_duration : float = 0.5
@export var vision_area : VisionArea
@export var attack_area : HurtBox
@export var next_state : EnemyState

var _timer : float = 0.0
var _direction : Vector2
var _can_see_player : bool = false


func init() -> void:
	# This function now sets up the signal connections for this state.
	# It's called once when the state machine is initialized.
	if vision_area:
		vision_area.player_entered.connect( _on_player_enter )
		vision_area.player_exited.connect( _on_player_exit )

## Called when the enemy enters the Chase state.
func enter() -> void:
	_timer = state_aggro_duration
	
	# Immediately face the player upon entering the chase state.
	_direction = enemy.global_position.direction_to( PlayerManager.player.global_position )
	enemy.set_direction( _direction )

	enemy.update_animation( anim_name )
	if attack_area:
		attack_area.monitoring = true

## Called when the enemy exits the Chase state.
func exit() -> void:
	if attack_area:
		attack_area.monitoring = false
	_can_see_player = false

## Handles the logic for each frame while in the Chase state.
func process( _delta: float ) -> EnemyState:
	# Continuously update the direction towards the player.
	var new_dir : Vector2 = enemy.global_position.direction_to( PlayerManager.player.global_position )
	_direction = lerp( _direction, new_dir, turn_rate ).normalized()
	enemy.velocity = _direction * chase_speed
	
	# Update animation only if the direction changes.
	if enemy.set_direction( _direction ):
		enemy.update_animation( anim_name )
	
	# If the player is no longer visible, start a timer.
	# If the timer runs out, transition to the next state (e.g., Idle or Search).
	if not _can_see_player:
		_timer -= _delta
		if _timer <= 0:
			return next_state
	else:
		# Reset the timer if the player is seen again.
		_timer = state_aggro_duration
		
	return null

## Physics-related logic for the Chase state (currently unused).
func physics( _delta: float ) -> EnemyState:
	return null	

func _on_player_enter() -> void:
	_can_see_player = true
	# If the enemy is not already chasing, switch to the Chase state.
	# This ensures the enemy reacts to the player from any state (Idle, Wander, etc.).
	if state_machine.current_state != self:
		state_machine.ChangeState( self )
	
func _on_player_exit() -> void:
	# Update the flag when the player leaves the vision area.
	_can_see_player = false
