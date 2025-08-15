class_name State_Damaged extends State

@export var knockback_speed : float = 200.0
@export var decelerate_speed : float = 10.0
@export var invulnerable_duration : float = 1.0

var _hurtbox : HurtBox
var _knockback_direction : Vector2
var next_state : State = null

@onready var idle: State_Idle = $"../Idle"
@onready var crouch: State = $"../Crouch" # Added to restore forced crouch cleanly

func init() -> void:
	player.damaged.connect(_on_player_damaged)

func enter() -> void:
	if not _hurtbox:
		push_warning("Damaged state entered without a HurtBox!")
		state_machine.change_state(idle)
		return

	player.update_animation("damaged")
	player.sprite.animation_finished.connect(_animation_finished)

	_knockback_direction = _hurtbox.global_position.direction_to(player.global_position)
	player.velocity = _knockback_direction * knockback_speed

	player.last_direction = _knockback_direction.normalized()
	player.update_animation("damaged")
	player.make_invulnerable(invulnerable_duration)

func exit() -> void:
	next_state = null
	_hurtbox = null
	if player.sprite.is_connected("animation_finished", _animation_finished):
		player.sprite.animation_finished.disconnect(_animation_finished)

func process(_delta: float) -> State:
	player.velocity = player.velocity.move_toward(Vector2.ZERO, decelerate_speed)
	return next_state

func physics(_delta: float) -> State:
	return null

func _on_player_damaged(hurtbox: HurtBox) -> void:
	_hurtbox = hurtbox
	state_machine.change_state(self)

func _animation_finished() -> void:
	# After damage, if area is forced -> return to crouch posture (apply_posture handles it),
	# else go to idle (player may have uncrouched on damage).
	if PlayerManager.level_forces_crouch : #or PlayerManager.crouch_preference
		next_state = crouch if PlayerManager.level_forces_crouch else idle  # or PlayerManager.crouch_preference
	else:
		next_state = idle
