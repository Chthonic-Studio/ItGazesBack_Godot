extends Node

const PLAYER = preload("res://Scenes/player.tscn")

signal interact_pressed
signal sanity_changed(new_sanity)
signal anxiety_changed(new_anxiety)

var player : Player 
var player_spawned : bool = false
var is_crouched : bool = false
var spawn_hidden : bool = false
var can_stand_up : bool = true

var level_forces_crouch : bool = false

# --- Player Mental State ---
var max_sanity : int = 10
var sanity : int = 10:
	set(value):
		sanity = clampi(value, 0, max_sanity)
		sanity_changed.emit(sanity)

var max_anxiety : int = 10
var anxiety : int = 10:
	set(value):
		anxiety = clampi(value, 0, max_anxiety)
		anxiety_changed.emit(anxiety)
# ---------------------------

func _ready() -> void:
	add_player_instance()
	await get_tree().create_timer(0.2).timeout
	player_spawned = true

func add_player_instance() -> void:
	player = PLAYER.instantiate()
	add_child( player )
	if is_crouched:
		player.state_machine.set_initial_state("crouch")
	if can_stand_up == false:
		player.state_machine.set_initial_state("crouch")
	if level_forces_crouch == true:
		player.state_machine.set_initial_state("crouch")

# --- Public functions to modify mental state ---
func update_sanity(delta: int) -> void:
	self.sanity += delta

func update_anxiety(delta: int) -> void:
	self.anxiety += delta
# ---------------------------------------------
	
func set_health( hp : int, max_hp : int ) -> void:
	player.max_hp = max_hp
	player.hp = hp
	player.update_hp( 0 )

func set_player_position( _new_pos : Vector2 ) -> void:
	player.global_position = _new_pos

func set_as_parent( _p : Node2D ) -> void:
	if player.get_parent():
		player.get_parent().remove_child( player )
	_p.add_child( player )

func unparent_player() -> void:
	if player.get_parent():
		player.get_parent().remove_child(player)
