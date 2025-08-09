class_name State_Damaged extends State

@export var knockback_speed : float = 200.0
@export var decelerate_speed : float = 10.0
@export var invulnerable_duration : float = 1.0

var hurtbox : HurtBox
var direction : Vector2
var next_state : State = null

@onready var idle: State_Idle = $"../Idle"


func _ready() -> void:
	pass

func init() -> void:
	player.damaged.connect( _player_damaged )

func enter() -> void:
	player.update_animation("damaged")
	player.sprite.animation_finished.connect( _animation_finished )
	
	direction = player.global_position.direction_to( hurtbox.global_position )
	player.velocity = direction *- knockback_speed
	player.set_direction()
	
	player.make_invulnerable( invulnerable_duration )
	

func exit() -> void:
	next_state = null
	player.sprite.animation_finished.disconnect( _animation_finished )
	
func process( _delta : float ) -> State:
	player.velocity -= player.velocity * decelerate_speed * _delta
	return next_state

func _physics_process(delta: float) -> void:
	pass

func _player_damaged(  ) -> void:
	state_machine.change_state(self)
	
func _animation_finished() -> void:
	next_state = idle
	
