extends Node

## AudioManager: A global singleton for managing all audio playback.
## Handles playing music, SFX, and managing dynamic audio like chase themes.

# --- How to use ---
# 1. This script is added to the Autoload list in Project -> Project Settings.
# 2. From any script, you can now call its functions, e.g.:
#    AudioManager.play_sfx(my_audio_data_resource, self.global_position)
#    AudioManager.play_music(my_music_stream)

# --- Music Configuration ---
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
	# --- MODIFICATION ---
	# We now create the music player in code since it's no longer in a scene.
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Music" # Assign it to the correct bus.
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
func play_sfx(data: AudioData, position: Vector2) -> void:
	if not data or data.audio_streams.is_empty():
		return

	var player = _sfx_player_pool[_sfx_player_index]
	_sfx_player_index = (_sfx_player_index + 1) % SFX_PLAYER_POOL_SIZE

	player.stream = data.audio_streams.pick_random()
	player.global_position = position
	player.pitch_scale = randf_range(data.min_pitch, data.max_pitch)
	player.volume_db = randf_range(data.min_volume_db, data.max_volume_db)
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
		tween.tween_property(music_player, "volume_db", -80.0, CHASE_FADE_OUT_TIME).finished.connect(music_player.stop)
		_current_music = null

## Gets the footstep sound data for a given material name.
func get_footstep_data(material_name: String) -> AudioData:
	return footstep_data_map.get(material_name, null)


# --- Private Helpers ---

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
