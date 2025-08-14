extends Node

const PLAYER = preload("res://Scenes/player.tscn")

signal interact_pressed
# Signal to notify listeners when sanity changes.
signal sanity_changed(new_sanity)
# Signal to notify listeners when anxiety changes.
signal anxiety_changed(new_anxiety)

var player : Player 
var player_spawned : bool = false
var is_crouched : bool = false
var spawn_hidden : bool = false

# --- Player Mental State ---
var max_sanity : int = 10
var sanity : int = 10:
	set(value):
		# Ensure sanity value is always clamped between 0 and max_sanity.
		sanity = clampi(value, 0, max_sanity)
		# Emit the signal so UI or other systems can react.
		sanity_changed.emit(sanity)

var max_anxiety : int = 10
var anxiety : int = 10:
	set(value):
		# Ensure anxiety value is always clamped between 0 and max_anxiety.
		anxiety = clampi(value, 0, max_anxiety)
		# Emit the signal so UI or other systems can react.
		anxiety_changed.emit(anxiety)
# ---------------------------

func _ready() -> void:
	add_player_instance()
	await get_tree().create_timer(0.2).timeout
	player_spawned = true

func add_player_instance() -> void:
	player = PLAYER.instantiate()
	add_child( player )

# --- Public functions to modify mental state ---
# Use these functions from other parts of the game to damage or restore sanity/anxiety.
# Example: PlayerManager.update_sanity(-1) to decrease sanity by 1.
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
