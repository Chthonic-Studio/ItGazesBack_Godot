class_name Player extends CharacterBody2D

@export_category("Health")
@export var max_hp : int = 6
@export var hp : int = 6
@export var invulnerable : bool = false

var is_crouched : bool = false:
	set(value):
		if is_crouched != value:
			is_crouched = value
			PlayerManager.is_crouched = value
			crouch_toggled.emit(is_crouched)

var is_hidden : bool = false

var can_stand_up : bool = true:
	set(value):
		if can_stand_up != value:
			can_stand_up = value
			PlayerManager.can_stand_up = value

var last_direction : Vector2 = Vector2.DOWN
var direction : Vector2 = Vector2.ZERO

const PROMPT_SCENE = preload("res://GUI/interact_prompt.tscn")
var _interaction_prompt: InteractionPrompt
var _available_interactable: Interactable = null

@onready var sprite : AnimatedSprite2D = $PlayerSprite
@onready var state_machine: PlayerStateMachine = $StateMachine
@onready var hitbox : HitBox = $HitBox
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

signal player_damaged ( damage_amount : int )
signal damaged ( hurtbox : HurtBox )
signal direction_changed ( new_direction : Vector2 )
signal crouch_toggled( is_crouched : bool )

# The player_ready signal is no longer needed with this new, simpler logic.
# signal player_ready

func _ready() -> void:
	if PlayerManager.level_forces_crouch:
		# If it does, we set both flags to ensure the player is crouched and cannot stand up.
		self.is_crouched = true
		self.can_stand_up = false
	else:
		# If the level is normal, we restore the player's previous crouch state
		# and ensure they are allowed to stand up.
		self.is_crouched = PlayerManager.is_crouched
		self.can_stand_up = true

	# 2. Initialize the state machine.
	state_machine.initialize(self)
	
	# 3. Set the initial animation state based on the logic above.
	if self.is_crouched:
		state_machine.set_initial_state("Crouch")
	
	# The rest of the setup proceeds as normal.
	hitbox.damaged.connect(_take_damage)
	_interaction_prompt = PROMPT_SCENE.instantiate()
	add_child(_interaction_prompt)
	_interaction_prompt.position.y = -sprite.sprite_frames.get_frame_texture("idle_down", 0).get_height() / 2 - 10
		
func _process( delta ):
	direction = Input.get_vector("left", "right", "up", "down")

	if Input.is_action_just_pressed("interact") and _available_interactable:
		if is_hidden:
			_available_interactable.on_hidden_interact(self)
		else:
			_available_interactable.on_interact(self)
	
func _physics_process( delta ):
	move_and_slide()
	
func update_animation_direction() -> void:
	if direction == Vector2.ZERO:
		return

	var new_direction := Vector2.ZERO
	
	if abs(direction.x) > 0.2:
		new_direction.x = sign(direction.x)
	if abs(direction.y) > 0.2:
		new_direction.y = sign(direction.y)
	
	if new_direction != last_direction:
		last_direction = new_direction
		direction_changed.emit(last_direction)
		state_machine.update_animation()

func get_anim_direction_string() -> String:
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
	
	var rounded_dir = last_direction.round()
	return direction_map.get(rounded_dir, "down")
	
func update_animation( state : String ) -> void:
	var anim_dir = get_anim_direction_string()
	var anim_name = state + "_" + anim_dir
	
	if sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)
	else:
		if anim_dir.contains("up"):
			sprite.play(state + "_up")
		elif anim_dir.contains("down"):
			sprite.play(state + "_down")
		elif anim_dir.contains("left"):
			sprite.play(state + "_left")
		elif anim_dir.contains("right"):
			sprite.play(state + "_right")

# This function is no longer needed, as the logic is now handled in _ready.
# func set_forced_crouch(is_forced: bool) -> void:
# 	can_stand_up = not is_forced
# 	if is_forced and not is_crouched:
# 		state_machine.change_state(state_machine.get_node("Crouch"))

func _take_damage( damage_amount: int, hurtbox: HurtBox ) -> void:
	if invulnerable:
		return
	
	if is_crouched:
		is_crouched = false
		
	update_hp( -damage_amount )
	player_damaged.emit( damage_amount )
	damaged.emit( hurtbox )
	
	if hp <= 0:
		print("Player has been defeated!")
	
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

#region Interactable
func on_interactable_entered(interactable: Interactable):
	_available_interactable = interactable
	_interaction_prompt.set_text(interactable.get_prompt_text())
	_interaction_prompt.show_prompt()

func on_interactable_exited(interactable: Interactable):
	if _available_interactable == interactable:
		_available_interactable = null
		_interaction_prompt.hide_prompt()
		
func update_hidden_prompt():
	if _available_interactable:
		var hidden_text = _available_interactable.get_hidden_prompt_text()
		if hidden_text != "":
			_interaction_prompt.set_text(hidden_text)
			_interaction_prompt.show_prompt()
		else:
			_interaction_prompt.hide_prompt()

func set_hidden_state(is_entering_hidden_state: bool):
	is_hidden = is_entering_hidden_state
	sprite.visible = not is_entering_hidden_state

func enter_hidden_state_on_spawn(interactable: Interactable):
	_available_interactable = interactable
	state_machine.change_state(state_machine.get_node("Hidden"))

func exit_hidden_state():
	if state_machine.current_state is State_Hidden:
		var next_state = state_machine.get_node("Crouch") if PlayerManager.is_crouched else state_machine.get_node("Idle")
		state_machine.change_state(next_state)
#endregion
