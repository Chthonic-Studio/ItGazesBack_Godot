class_name Enemy extends CharacterBody2D

signal direction_changed ( new_direction : Vector2 )
signal enemy_damaged ()

var last_direction : Vector2 = Vector2.DOWN
var direction : Vector2 = Vector2.ZERO

@export var HP : int = 3

@onready var sprite : AnimatedSprite2D = $EnemySprite

var player : Player
var invulnerable : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
