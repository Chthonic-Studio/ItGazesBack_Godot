class_name State_Run extends State

@export var run_speed : float = 200.0

@onready var idle: State = $"../Idle"
@onready var walk: State = $"../Walk"
@onready var crouch_run: State = $"../CrouchRun"

func enter() -> void:
	player.update_animation("run")

func process(_delta: float) -> State:
	# If the run button is released, go back to Walk (which will quickly go to Idle if no movement).
	if not Input.is_action_pressed("run"):
		return walk
	
	# If the player stops moving, go to Idle.
	if player.direction == Vector2.ZERO:
		return idle
	
	# If crouch is toggled while running, switch to CrouchRun.
	if Input.is_action_just_pressed("crouch") and player.can_stand_up:
		return crouch_run
	
	return null

func physics(_delta: float) -> State:
	player.velocity = player.direction * run_speed
	# This call is correct and needs to stay. It detects when the direction changes.
	player.update_animation_direction()
	return null

func update_animation() -> void:
	player.update_animation("run")
