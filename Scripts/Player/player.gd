class_name Player extends CharacterBody2D

@export_category("Health")
@export var max_hp : int = 6
@export var hp : int = 6
@export var invulnerable : bool = false

@export_category("State Booleans")
# This is true when the player is in a crouch state. Controlled by the state machine.
var is_crouched : bool = false:
	set(value):
		if is_crouched != value:
			is_crouched = value
			# Notify the PlayerManager so the state persists between scenes.
			PlayerManager.is_crouched = value
			crouch_toggled.emit(is_crouched)

# This is used by levels to prevent the player from standing up (e.g., in vents).
var can_stand_up : bool = true

# We'll store the last non-zero direction to keep facing the same way when idle.
var last_direction : Vector2 = Vector2.DOWN
var direction : Vector2 = Vector2.ZERO

@onready var sprite : AnimatedSprite2D = $PlayerSprite
@onready var state_machine: PlayerStateMachine = $StateMachine
@onready var hitbox : HitBox = $HitBox

signal player_damaged ( damage_amount : int )
# This signal will now carry the HurtBox reference to the state machine.
signal damaged ( hurtbox : HurtBox )
signal direction_changed ( new_direction : Vector2 )
signal crouch_toggled( is_crouched : bool )

func _ready() -> void:
	state_machine.initialize(self)
	hitbox.damaged.connect(_take_damage)
	
	if PlayerManager.is_crouched:
		# We can't change state directly, as the state machine isn't ready.
		# So we tell the state machine to start in the Crouch state instead of Idle.
		state_machine.set_initial_state("Crouch")
		
func _process( delta ):
	# get_vector is perfect for 8-directional movement.
	# It automatically handles normalization, so the player doesn't move faster diagonally.
	direction = Input.get_vector("left", "right", "up", "down")
	
func _physics_process( delta ):
	# This function's only job is to execute the movement based on the 
	# velocity calculated by the current state (Walk, Idle, etc.).
	move_and_slide()
	
func update_animation_direction() -> void:
	# Only update if the player is actually moving.
	if direction == Vector2.ZERO:
		return

	# We determine the dominant direction by looking at the vector's components.
	# This is far more reliable than angle calculations.
	var new_direction := Vector2.ZERO
	
	if abs(direction.x) > 0.2:
		new_direction.x = sign(direction.x)
	if abs(direction.y) > 0.2:
		new_direction.y = sign(direction.y)
	
	# Only update the animation if the resulting direction has changed.
	if new_direction != last_direction:
		last_direction = new_direction
		# We don't need to emit the direction_changed signal here unless another
		# system depends on the 8-way vector. For now, we'll keep it for the
		# InteractionHost, but it could be removed if that's not needed.
		direction_changed.emit(last_direction)
		state_machine.update_animation()

# This function will determine the animation suffix (e.g., "down", "up_left").
func get_anim_direction_string() -> String:
	# Define the mapping from a direction vector to its animation suffix.
	# This is done once and stored for efficiency.
	var direction_map := {
		Vector2(0, 1): "down",
		Vector2(0, -1): "up",
		Vector2(1, 0): "right",
		Vector2(-1, 0): "left",
		Vector2(1, 1): "down_right",
		Vector2(-1, 1): "down_left",
		Vector2(1, -1): "up_right",
		Vector2(-1, -1): "up_left"
	}
	
	# The .round() is crucial here. It converts the direction vector into a clean,
	# grid-aligned vector (e.g., (0.707, -0.707) becomes (1, -1)),
	# which can be used as a key in our dictionary.
	var rounded_dir = last_direction.round()
	
	# Look up the rounded direction in our map.
	# If it's not found (which shouldn't happen with the current logic),
	# default to "down" to prevent a crash.
	return direction_map.get(rounded_dir, "down")
	
func update_animation( state : String ) -> void:
	var anim_dir = get_anim_direction_string()
	var anim_name = state + "_" + anim_dir
	
	# To prevent crashes, we check if the animation exists before playing it.
	if sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)
	else:
		# If a diagonal animation is missing, fall back to a cardinal one.
		if anim_dir.contains("up"):
			sprite.play(state + "_up")
		elif anim_dir.contains("down"):
			sprite.play(state + "_down")
		elif anim_dir.contains("left"):
			sprite.play(state + "_left")
		elif anim_dir.contains("right"):
			sprite.play(state + "_right")

# Called by the Level to force the player to crouch or allow them to stand.
func set_forced_crouch(is_forced: bool) -> void:
	can_stand_up = not is_forced
	if is_forced and not is_crouched:
		# Force the player into the crouch state if they aren't already.
		state_machine.change_state(state_machine.get_node("Crouch"))



# The function now accepts the hurtbox that dealt the damage.
func _take_damage( damage_amount: int, hurtbox: HurtBox ) -> void:
	if invulnerable:
		return
	
	if is_crouched:
		is_crouched = false
		
	update_hp( -damage_amount )
	player_damaged.emit( damage_amount )
	# Emit the damaged signal with the hurtbox reference.
	damaged.emit( hurtbox )
	
	# For now, we'll just print the HP, but this is where you would
	# add logic for player death when HP reaches 0.
	if hp <= 0:
		print("Player has been defeated!")
		# Example: get_tree().reload_current_scene()
	
func update_hp( delta : int ) -> void:
	hp = clampi( hp + delta, 0, max_hp )
	print ("Player HP = " + str(hp))
	pass
	
func make_invulnerable( _duration : float = 1.0 ) -> void:
	invulnerable = true
	hitbox.monitoring = false
	
	await get_tree().create_timer( _duration ).timeout
	
	invulnerable = false
	hitbox.monitoring = true
