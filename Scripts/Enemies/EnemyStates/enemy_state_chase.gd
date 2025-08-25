class_name EnemyStateChase extends EnemyState

const PATHFINDER : PackedScene	= preload ("res://Scenes/Enemies/pathfinder.tscn") 

@export var anim_name : String = "walk"
@export var chase_speed : float = 40.0
@export var turn_rate : float = 0.25

@export_category("AI")
@export var state_aggro_duration : float = 0.5
@export var vision_area : VisionArea
@export var attack_area : HurtBox
@export var next_state : EnemyState

var pathfinder : Pathfinder

var _timer : float = 0.0
var _direction : Vector2
var _can_see_player : bool = false


func init() -> void:
	if vision_area:
		vision_area.player_entered.connect( _on_player_enter )
		vision_area.player_exited.connect( _on_player_exit )

func enter() -> void:
	pathfinder = PATHFINDER.instantiate() as Pathfinder
	enemy.add_child( pathfinder )
	_timer = state_aggro_duration
	
	# --- REASON FOR CHANGE ---
	# Check if the player exists and is not hidden before chasing.
	if PlayerManager.player and not PlayerManager.player.is_hidden:
		_direction = enemy.global_position.direction_to( PlayerManager.player.global_position )
		enemy.set_direction( _direction )

	enemy.update_animation( anim_name )
	if attack_area:
		attack_area.monitoring = true

func exit() -> void:
	pathfinder.queue_free()
	if attack_area:
		attack_area.monitoring = false
	_can_see_player = false

func process( _delta: float ) -> EnemyState:
	# Add a check here to ensure we don't try to chase a hidden player.
	if not PlayerManager.player or PlayerManager.player.is_hidden:
		# If player is hidden, treat it as if they are not visible.
		_can_see_player = false
	
	if PlayerManager.player and not PlayerManager.player.is_hidden:
		var new_dir : Vector2 = enemy.global_position.direction_to( PlayerManager.player.global_position )
		_direction = lerp( _direction, pathfinder.move_dir, turn_rate ).normalized()
		enemy.velocity = _direction * chase_speed
		
		if enemy.set_direction( _direction ):
			enemy.update_animation( anim_name )
	
	if not _can_see_player:
		_timer -= _delta
		if _timer <= 0:
			return next_state
	else:
		_timer = state_aggro_duration
		
	return null

func physics( _delta: float ) -> EnemyState:
	return null	

func _on_player_enter() -> void:
	# --- REASON FOR CHANGE ---
	# Only become aggressive if the player is not hidden.
	if PlayerManager.player and not PlayerManager.player.is_hidden:
		_can_see_player = true
		if state_machine.current_state != self:
			state_machine.ChangeState( self )
	
func _on_player_exit() -> void:
	_can_see_player = false
