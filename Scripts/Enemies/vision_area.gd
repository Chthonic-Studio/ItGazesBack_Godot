class_name VisionArea extends Area2D

signal player_detected()
signal player_lost()

# --- How to use ---
# This script creates a sophisticated vision system for an enemy.
# It should be placed on an Area2D node that is a grandchild of the main Enemy node,
# like: Enemy > Interactions > VisionArea.
# The Enemy script must have the vision_angle, vision_range_*, and absolute_detection_radius properties.
# This script will automatically handle line-of-sight checks and player state (crouching/standing).

var enemy: Enemy
@onready var line_of_sight: RayCast2D = $LineOfSight
@onready var perception_range_shape: CollisionShape2D = $PerceptionRange
@onready var absolute_range_shape: CollisionShape2D = $AbsoluteRange

var _player_in_perception_range: bool = false
var _player_is_detected: bool = false

func _ready() -> void:
	# Correctly get the grandparent 'Enemy' node.
	enemy = get_parent().get_parent()
	if not enemy is Enemy:
		push_error("VisionArea's parent's parent is not an Enemy! Check scene structure.")
		return

	# Connect signals for initial detection.
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Configure the collision shapes based on the enemy's properties.
	_configure_shapes()
	
	# Connect to the enemy's direction signal to rotate this node.
	if enemy.has_signal("direction_changed"):
		enemy.direction_changed.connect(_on_direction_changed)
	
	# Set initial rotation based on the enemy's starting direction.
	_on_direction_changed(enemy.last_direction)


func _physics_process(_delta: float) -> void:
	if not _player_in_perception_range:
		return
		
	var is_now_detected = _check_player_detection()
	
	if is_now_detected and not _player_is_detected:
		_player_is_detected = true
		player_detected.emit()
	elif not is_now_detected and _player_is_detected:
		_player_is_detected = false
		player_lost.emit()


# This is the main detection brain, now with angle checks.
func _check_player_detection() -> bool:
	var player = PlayerManager.player
	if not is_instance_valid(player) or player.is_hidden:
		return false

	var player_pos = player.global_position
	var enemy_pos = enemy.global_position
	
	# 1. Absolute Range Check (Circle): Is player in our "personal space"?
	if enemy_pos.distance_to(player_pos) <= enemy.absolute_detection_radius:
		if _is_line_of_sight_clear(player_pos):
			return true

	# 2. Cone-based Check
	var vector_to_player = (player_pos - enemy_pos)
	var distance_to_player = vector_to_player.length()

	# Check distance based on player state first.
	var current_vision_range = enemy.vision_range_crouching if player.is_crouched else enemy.vision_range_standing
	if distance_to_player > current_vision_range:
		return false # Player is too far away.

	# Check if player is within the vision angle.
	# The enemy's forward vector is its 'last_direction', but rotated to match the VisionArea's orientation.
	var forward_vector = Vector2.DOWN.rotated(rotation)
	var angle_to_player = forward_vector.angle_to(vector_to_player.normalized())

	if abs(angle_to_player) > deg_to_rad(enemy.vision_angle):
		return false # Player is outside the vision cone angle.

	# 3. Final Line of Sight Check
	return _is_line_of_sight_clear(player_pos)


func _is_line_of_sight_clear(target_position: Vector2) -> bool:
	line_of_sight.target_position = to_local(target_position)
	line_of_sight.force_raycast_update()
	if line_of_sight.is_colliding():
		return line_of_sight.get_collider() is Player
	return true

# This function dynamically builds the visual cone for debugging.
func _configure_shapes() -> void:
	(absolute_range_shape.shape as CircleShape2D).radius = enemy.absolute_detection_radius
	
	var max_range = max(enemy.vision_range_standing, enemy.vision_range_crouching)
	var angle_rad = deg_to_rad(enemy.vision_angle)
	
	var points = PackedVector2Array()
	points.append(Vector2.ZERO)
	
	points.append(Vector2(sin(-angle_rad), cos(-angle_rad)) * max_range) # Changed from -cos to cos
	points.append(Vector2(sin(angle_rad), cos(angle_rad)) * max_range)  # Changed from -cos to cos
	
	var polygon_shape = ConvexPolygonShape2D.new()
	polygon_shape.points = points
	perception_range_shape.shape = polygon_shape

# --- Signal Handlers ---
func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_in_perception_range = true

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_in_perception_range = false
		if _player_is_detected:
			_player_is_detected = false
			player_lost.emit()

# Rotate the entire VisionArea node to match the enemy's facing direction.
func _on_direction_changed(new_direction: Vector2) -> void:
	# The angle is calculated relative to Vector2.DOWN because the cone points "down" in local space.
	rotation = Vector2.DOWN.angle_to(new_direction)
