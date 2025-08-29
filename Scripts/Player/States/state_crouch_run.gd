class_name State_CrouchRun extends State

@export var crouch_walk_speed : float = 50.0
@export var crouch_run_speed : float = 100.0

@onready var crouch: State = $"../Crouch"
@onready var run: State = $"../Run"
@onready var walk: State = $"../Walk"
@onready var hidden: State = $"../Hidden"

func enter() -> void:
	player.is_crouched = true
	update_animation()

func exit() -> void:
	pass

func process(_delta: float) -> State:
	# Stop -> base crouch
	if player.direction == Vector2.ZERO:
		return crouch
	
	# Toggle crouch -> stand attempt
	if Input.is_action_just_pressed("crouch"):
		if player.can_stand_up:
			# Decide stand target (run or walk)
			player.is_crouched = false
			PlayerManager.is_crouched = false
			if Input.is_action_pressed("run"):
				return run
			return walk
		else:
			player.show_blocked_stand_message()
	
	# Run key changes animation variant
	if Input.is_action_just_pressed("run") or Input.is_action_just_released("run"):
		update_animation()
	return null

func physics(_delta: float) -> State:
	var is_running = Input.is_action_pressed("run")
	var current_speed = crouch_run_speed if is_running else crouch_walk_speed
	player.velocity = player.direction * current_speed
	player.update_animation_direction()
	
	# --- NEW ---
	# Determine the correct multipliers based on whether the player is crouch-running or crouch-walking.
	var speed_mod = 1.5 if is_running else 1.2
	var volume_mod = 0.5 if is_running else 0.2
	player.handle_footstep_audio(_delta, speed_mod, volume_mod)
	# --- END NEW ---
	
	return null
	
func update_animation() -> void:
	var anim_name = "crouch_run" if Input.is_action_pressed("run") else "crouch_walk"
	player.update_animation(anim_name)
