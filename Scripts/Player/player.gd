class_name Player extends CharacterBody2D

@export_category("Health")
@export var max_hp : int = 10
@export var hp : int = 10
@export var invulnerable : bool = false

@export_category("Audio")
@export var footstep_timer_delay: float = 0.8 # Time between footstep sounds when walking
var _footstep_timer: float = 0.0

var is_crouched : bool = false:
	set(value):
		if is_crouched != value:
			is_crouched = value
			PlayerManager.is_crouched = value
			crouch_toggled.emit(is_crouched)

var is_hidden : bool = false

var _temp_prompt_active: bool = false
var _temp_prompt_saved_text: String = ""
var _temp_prompt_timer: SceneTreeTimer

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

func _ready() -> void:
	# 1. Decide starting crouch BEFORE initializing state machine (order critical).
	var start_crouched : bool = PlayerManager.level_forces_crouch or PlayerManager.is_crouched
	state_machine.set_initial_state("Crouch" if start_crouched else "Idle")
	state_machine.initialize(self)
	
	# 2. Now set runtime posture flags (these may emit signals).
	is_crouched = start_crouched
	can_stand_up = not PlayerManager.level_forces_crouch
	
	# 3. Hook damage & prompt.
	hitbox.damaged.connect(_take_damage)
	_interaction_prompt = PROMPT_SCENE.instantiate()
	# --- CORRECTED LOGIC ---
	# Set the player itself as the target for the prompt to follow.
	_interaction_prompt.target_node = self
	# Add the prompt to the scene tree. Since it's a CanvasLayer, it can be added anywhere.
	add_child(_interaction_prompt)
	# --- END CORRECTION ---
		
func _process( delta ):
	direction = Input.get_vector("left", "right", "up", "down")

	_check_interactable_overlap()

	if Input.is_action_just_pressed("interact") and _available_interactable:
		# Safety: re‑check (edge case if overlap lost this frame).
		if not _is_still_overlapping(_available_interactable):
			_clear_interactable()
		else:
			if is_hidden:
				_available_interactable.on_hidden_interact(self)
			else:
				_available_interactable.on_interact(self)
	
	# --- REMOVED ---
	# All positioning logic has been moved to interaction_prompt.gd
	# --- END REMOVED ---

# Returns true only if we are still physically overlapping the interactable's Area2D.
func _is_still_overlapping(interactable: Interactable) -> bool:
	if not interactable:
		return false
	if not is_instance_valid(interactable):
		return false
	if interactable is Area2D:
		# get_overlapping_bodies() is cheap for small lists; ok per frame.
		var bodies = (interactable as Area2D).get_overlapping_bodies()
		return bodies.has(self)
	return false

# Per-frame guard: if no longer overlapping, clear and hide prompt.
func _check_interactable_overlap() -> void:
	if _available_interactable and not _is_still_overlapping(_available_interactable):
		_clear_interactable()

# Centralized clear (so future logic like temp prompts can hook here).
func _clear_interactable() -> void:
	_available_interactable = null
	if _interaction_prompt:
		_interaction_prompt.hide_prompt()
	
func _physics_process( delta ):
	move_and_slide()

func handle_footstep_audio(delta: float, speed_multiplier: float = 1.0, volume_multiplier: float = 0.5) -> void:
	_footstep_timer -= delta
	if _footstep_timer <= 0:
		# The timer delay is now adjusted by the speed_multiplier from the state.
		# A lower multiplier (e.g., 0.6 for crouch) results in a longer delay (slower footsteps).
		_footstep_timer = footstep_timer_delay / speed_multiplier
		
		var main_tilemap = LevelManager.main_tilemap
		if not main_tilemap: return

		var tile_coords: Vector2i = main_tilemap.local_to_map(global_position)
		var tile_data: TileData = main_tilemap.get_cell_tile_data(tile_coords)
		
		if tile_data:
			var material_name = tile_data.get_custom_data("footstep_material")
			if not material_name.is_empty():
				var footstep_sfx = AudioManager.get_footstep_data(material_name)
				if footstep_sfx:
					# We pass the volume multiplier to the AudioManager now.
					AudioManager.play_sfx(footstep_sfx, global_position, volume_multiplier)
	
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
		var next_state = state_machine.get_node("Crouch") if (PlayerManager.is_crouched or PlayerManager.level_forces_crouch) else state_machine.get_node("Idle")
		state_machine.change_state(next_state)
#endregion

# show_blocked_stand_message: Call from states when player tries to stand but cannot.
func show_blocked_stand_message() -> void:
	show_temp_prompt("Can't stand up here")

# Generic helper to show a temporary prompt for 'duration' seconds.
func show_temp_prompt(msg: String, duration: float = 2.0) -> void:
	if not _interaction_prompt:
		return
	if not _temp_prompt_active:
		_temp_prompt_saved_text = _interaction_prompt.label.text
	_temp_prompt_active = true
	_interaction_prompt.set_text(msg)
	_interaction_prompt.show_prompt()
	if _temp_prompt_timer:
		if _temp_prompt_timer.timeout.is_connected(_on_temp_prompt_timeout):
			_temp_prompt_timer.timeout.disconnect(_on_temp_prompt_timeout)
	_temp_prompt_timer = get_tree().create_timer(duration)
	_temp_prompt_timer.timeout.connect(_on_temp_prompt_timeout)

func _on_temp_prompt_timeout() -> void:
	_temp_prompt_active = false
	# Restore original prompt if still near an interactable; otherwise hide.
	if _available_interactable:
		var text = _available_interactable.get_prompt_text()
		if is_hidden and _available_interactable.get_hidden_prompt_text() != "":
			# If hidden and a hidden prompt exists, prefer it
			text = _available_interactable.get_hidden_prompt_text()
		_interaction_prompt.set_text(text)
		_interaction_prompt.show_prompt()
	else:
		_interaction_prompt.hide_prompt()
