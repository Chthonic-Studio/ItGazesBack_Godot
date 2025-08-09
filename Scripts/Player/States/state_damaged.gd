class_name State_Damaged extends State

@export var knockback_speed : float = 200.0
@export var decelerate_speed : float = 10.0
@export var invulnerable_duration : float = 1.0

var _hurtbox : HurtBox
var _knockback_direction : Vector2
var next_state : State = null

@onready var idle: State_Idle = $"../Idle"


func _ready() -> void:
	pass

func init() -> void:
	# Connect our new function to the player's damaged signal.
	player.damaged.connect( _on_player_damaged )

func enter() -> void:
	# This check prevents a crash if the state is entered incorrectly.
	if not _hurtbox:
		push_warning("Damaged state entered without a HurtBox!")
		# Immediately transition to idle to prevent getting stuck.
		state_machine.change_state(idle)
		return
		
	player.update_animation("damaged")
	player.sprite.animation_finished.connect( _animation_finished )
	
	# Calculate the knockback direction away from the HurtBox.
	_knockback_direction = _hurtbox.global_position.direction_to( player.global_position )
	player.velocity = _knockback_direction * knockback_speed
	
	# Update the player's facing direction to match the knockback.
	player.last_direction = _knockback_direction.normalized()
	player.update_animation("damaged") # Update animation to face correct direction
	
	player.make_invulnerable( invulnerable_duration )
	

func exit() -> void:
	next_state = null
	_hurtbox = null # Clear the hurtbox reference on exit.
	if player.sprite.is_connected("animation_finished", _animation_finished):
		player.sprite.animation_finished.disconnect( _animation_finished )
	
func process( _delta : float ) -> State:
	# Decelerate the knockback velocity over time.
	player.velocity = player.velocity.move_toward(Vector2.ZERO, decelerate_speed)
	return next_state

func physics( _delta : float ) -> State:
	return null

# This function will be called by the player's 'damaged' signal.
func _on_player_damaged( hurtbox : HurtBox ) -> void:
	# Store the hurtbox that hit the player.
	_hurtbox = hurtbox
	# Change to this state.
	state_machine.change_state(self)
	
func _animation_finished() -> void:
	next_state = idle
