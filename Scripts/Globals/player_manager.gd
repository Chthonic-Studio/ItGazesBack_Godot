extends Node

const PLAYER = preload("res://Scenes/player.tscn")

signal interact_pressed
signal sanity_changed(new_sanity)
signal anxiety_changed(new_anxiety)

var player : Player 
var player_spawned : bool = false
var is_crouched : bool = false		# Sticky memory across levels
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

# --- NEW: Claustrophobia Timers ---
# We use one-shot timers that we restart manually. This gives us more control than
# simply starting and stopping repeating timers, preventing edge cases where
# anxiety might change at the wrong moment.
var _anxiety_increase_timer: Timer
var _anxiety_decrease_timer: Timer
# ------------------------------------

func _ready() -> void:
	# Create and configure the timers via code. This is cleaner than adding them in the scene editor
	# for a global script.
	_anxiety_increase_timer = Timer.new()
	_anxiety_increase_timer.wait_time = 15.0 # Time in seconds to increase anxiety
	_anxiety_increase_timer.one_shot = true
	_anxiety_increase_timer.timeout.connect(_on_anxiety_increase_timeout)
	add_child(_anxiety_increase_timer)

	_anxiety_decrease_timer = Timer.new()
	_anxiety_decrease_timer.wait_time = 10.0 # Time in seconds to decrease anxiety
	_anxiety_decrease_timer.one_shot = true
	_anxiety_decrease_timer.timeout.connect(_on_anxiety_decrease_timeout)
	add_child(_anxiety_decrease_timer)
	# --- END NEW ---
	
	add_player_instance()
	await get_tree().create_timer(0.2).timeout
	player_spawned = true
	
	# --- NEW: Start initial anxiety check ---
	# This ensures the correct timer is running when the game first loads.
	_update_anxiety_timers()
	# --- END NEW ---
	
func _process(_delta: float) -> void:
	# This check ensures that if the player's state changes (e.g., hiding),
	# we react immediately rather than waiting for a level change.
	if player and player.is_node_ready():
		var is_claustrophobic = player.is_hidden or level_forces_crouch
		
		# If the player is in a tight space and the increase timer isn't running, start it.
		if is_claustrophobic and _anxiety_increase_timer.is_stopped():
			_update_anxiety_timers()
		# If the player is in an open space and the decrease timer isn't running, start it.
		elif not is_claustrophobic and _anxiety_decrease_timer.is_stopped():
			_update_anxiety_timers()

func add_player_instance() -> void:
	# NOTE: We no longer try to set the state machine initial state here.
	# Player decides that in its own _ready() with proper ordering.
	player = PLAYER.instantiate()
	add_child(player)

# --- Mental state helpers ---
func update_sanity(delta: int) -> void:
	self.sanity += delta

func update_anxiety(delta: int) -> void:
	self.anxiety += delta
# ----------------------------

# --- NEW: Claustrophobia System ---

# This function is the central brain for the system. It checks the player's
# condition and starts the correct timer while stopping the other.
func _update_anxiety_timers():
	if not player or not player.is_node_ready(): return
	
	var is_in_claustrophobic_space = player.is_hidden or level_forces_crouch
	
	if is_in_claustrophobic_space:
		# Player is in a vent or hiding. Stop recovery and start anxiety increase.
		if not _anxiety_decrease_timer.is_stopped():
			_anxiety_decrease_timer.stop()
		if _anxiety_increase_timer.is_stopped():
			_anxiety_increase_timer.start()
	else:
		# Player is in the open. Stop anxiety increase and start recovery.
		if not _anxiety_increase_timer.is_stopped():
			_anxiety_increase_timer.stop()
		if _anxiety_decrease_timer.is_stopped():
			_anxiety_decrease_timer.start()

# Called when the increase timer finishes.
func _on_anxiety_increase_timeout():
	update_anxiety(-1) # Decrease the numerical value, which increases the effect
	# Restart the timer for the next tick, but only if still in a tight space.
	if player.is_hidden or level_forces_crouch:
		_anxiety_increase_timer.start()

# Called when the decrease timer finishes.
func _on_anxiety_decrease_timeout():
	update_anxiety(1) # Increase the numerical value, which decreases the effect
	# Restart the timer for the next tick, but only if still in an open space.
	if not player.is_hidden and not level_forces_crouch:
		_anxiety_decrease_timer.start()
		
# ------------------------------------


func set_health( hp : int, max_hp : int ) -> void:
	player.max_hp = max_hp
	player.hp = hp
	player.update_hp(0)

func set_player_position( _new_pos : Vector2 ) -> void:
	player.global_position = _new_pos

func set_as_parent( _p : Node2D ) -> void:
	if player.get_parent():
		player.get_parent().remove_child(player)
	_p.add_child(player)

func unparent_player() -> void:
	if player.get_parent():
		player.get_parent().remove_child(player)
