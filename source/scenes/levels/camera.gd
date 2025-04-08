extends Camera2D

# Camera follow parameters
@export var target_path: NodePath
@export var follow_speed: float = 5.0

# Shake parameters
@export var decay: float = 0.8  # How quickly the shake effect stops
@export var max_offset: Vector2 = Vector2(30, 20)  # Maximum shake offset
@export var max_roll: float = 0.1  # Maximum shake rotation

var trauma: float = 0.0  # Current trauma level; 0 = no trauma, 1 = full trauma
var trauma_power: float = 2  # Trauma exponent for screen shake calculation

# The target node to follow (usually the player)
var target: Node2D = null

func _ready():
	# Add self to camera group
	add_to_group("camera")
	
	# Get the target if path is set
	if target_path:
		target = get_node(target_path)

func _physics_process(delta):
	# Follow target if assigned
	if target:
		# Smoothly move to target position
		global_position = global_position.lerp(target.global_position, follow_speed * delta)

func _process(delta):
	# Apply screen shake
	if trauma > 0:
		trauma = max(trauma - decay * delta, 0)
		_shake()
	elif offset != Vector2.ZERO or rotation != 0:
		# Reset camera when shake is done
		offset = Vector2.ZERO
		rotation = 0

# Add trauma to the screen shake system
func add_trauma(amount: float):
	trauma = min(trauma + amount, 1.0)

# Apply the shake effect
func _shake():
	var amount = pow(trauma, trauma_power)
	
	# Apply random rotation
	rotation = max_roll * amount * randf_range(-1, 1)
	
	# Apply random offset
	offset = Vector2(
		max_offset.x * amount * randf_range(-1, 1),
		max_offset.y * amount * randf_range(-1, 1)
	)

# Public function to shake the camera from anywhere
func shake_camera(amount: float = 0.5):
	add_trauma(amount)
