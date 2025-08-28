@tool
class_name AudioData extends Resource

## A custom resource to define a sound effect's properties.
## Create these in the FileSystem dock to define sounds like footsteps, UI clicks, etc.

# --- How to use ---
# 1. Right-click in the FileSystem, choose Create New -> Resource.
# 2. Search for and select "AudioData".
# 3. Save the file (e.g., "res://Assets/Audio/SFX/footstep_metal.tres").
# 4. In the Inspector, you can now assign audio streams and configure the sound.

@export_category("Sound Definition")
## An array of audio files. The AudioManager will pick one randomly.
@export var audio_streams: Array[AudioStream]

@export_group("Playback Properties")
## The audio bus this sound will play on (e.g., "SFX", "UI").
@export var bus: StringName = "SFX"
## The minimum pitch shift. 1.0 is normal pitch.
@export_range(0.5, 2.0) var min_pitch: float = 0.9
## The maximum pitch shift. 1.0 is normal pitch.
@export_range(0.5, 2.0) var max_pitch: float = 1.1
## The minimum volume adjustment (in decibels).
@export_range(-20, 0) var min_volume_db: float = 0.0
## The maximum volume adjustment (in decibels).
@export_range(-20, 0) var max_volume_db: float = 0.0

@export_group("Configuration")
## For footstep sounds, this links the sound to a tile material.
@export var footstep_material: String = ""
