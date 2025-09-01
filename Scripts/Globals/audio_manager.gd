extends Node

## AudioManager: A global singleton for managing all audio playback.
## Handles playing music, SFX, and managing dynamic audio like chase themes.

# All configuration is now done directly in the script for simplicity.
const CHASE_MUSIC: AudioStream = preload("res://Audio/Ambiance/ChaseAmbianceLoop.mp3") 
const CHASE_FADE_IN_TIME: float = 0.5
const CHASE_FADE_OUT_TIME: float = 3.0

# --- Node References ---
var music_player: AudioStreamPlayer

# --- Footstep Management ---
var footstep_data_map: Dictionary = {} # Maps material names to AudioData resources

# --- Chase Music Management ---
var _chase_source_count: int = 0
var _current_music: AudioStream

# --- SFX Player Pool ---
var _sfx_player_pool: Array[AudioStreamPlayer2D] = []
var _sfx_player_index: int = 0
const SFX_PLAYER_POOL_SIZE = 16 # Max simultaneous 2D sounds.

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Music" 
	add_child(music_player)
	
	# Create a pool of AudioStreamPlayer2D nodes to play spatial SFX.
	for i in range(SFX_PLAYER_POOL_SIZE):
		var player = AudioStreamPlayer2D.new()
		add_child(player)
		_sfx_player_pool.append(player)
	
	# Pre-load footstep data resources for quick lookup.
	_load_footstep_data("res://Audio/SFX/Footsteps/")

# --- Public API ---

## Plays a one-shot 2D sound effect at a specific location.
func play_sfx(data: AudioData, position: Vector2, volume_multiplier: float = 1.0) -> void:
	if not data or data.audio_streams.is_empty():
		return

	var player = _sfx_player_pool[_sfx_player_index]
	_sfx_player_index = (_sfx_player_index + 1) % SFX_PLAYER_POOL_SIZE

	# Calculate the final volume in dB, applying the multiplier.
	var base_volume_db = randf_range(data.min_volume_db, data.max_volume_db)
	var final_volume_db = base_volume_db + linear_to_db(volume_multiplier)

	player.stream = data.audio_streams.pick_random()
	player.global_position = position
	player.pitch_scale = randf_range(data.min_pitch, data.max_pitch)
	player.volume_db = final_volume_db # Use the final calculated volume.
	player.bus = data.bus
	player.play()

## Plays background music, cross-fading if something is already playing.
func play_music(stream: AudioStream, crossfade_time: float = 2.0) -> void:
	if not music_player or not stream or stream == _current_music:
		return
	
	_current_music = stream
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	if music_player.playing:
		tween.tween_property(music_player, "volume_db", -80.0, crossfade_time)
	
	music_player.stream = stream
	music_player.volume_db = -80.0
	music_player.play()
	tween.tween_property(music_player, "volume_db", 0.0, crossfade_time)

## Call this when an enemy starts chasing the player.
func start_chase(source: Node) -> void:
	_chase_source_count += 1
	if _chase_source_count == 1 and music_player.stream != CHASE_MUSIC:
		play_music(CHASE_MUSIC, CHASE_FADE_IN_TIME)

## Call this when an enemy stops chasing the player.
func stop_chase(source: Node) -> void:
	_chase_source_count = max(0, _chase_source_count - 1)
	if _chase_source_count == 0 and music_player.stream == CHASE_MUSIC:
		var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		# --- FIX ---
		# Connect the tween's finished signal to our new reset function.
		tween.tween_property(music_player, "volume_db", -80.0, CHASE_FADE_OUT_TIME).finished.connect(_on_chase_music_fade_out_finished)
		_current_music = null

## Gets the footstep sound data for a given material name.
func get_footstep_data(material_name: String) -> AudioData:
	return footstep_data_map.get(material_name, null)

# --- Private Helpers ---

# This function is called when the chase music has finished fading out.
func _on_chase_music_fade_out_finished() -> void:
	music_player.stop()
	music_player.stream = null # Explicitly clear the stream to allow re-triggering.

## Loads all AudioData resources from a given directory.
func _load_footstep_data(directory: String) -> void:
	var dir = DirAccess.open(directory)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var path = directory.path_join(file_name)
				var resource = load(path) as AudioData
				if resource and not resource.footstep_material.is_empty():
					footstep_data_map[resource.footstep_material] = resource
			file_name = dir.get_next()
