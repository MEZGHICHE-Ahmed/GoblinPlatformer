extends GPUParticles2D

# How long to wait before freeing the node after emission stops
@export var cleanup_delay: float = 1.0

func _ready():
	# Make sure one-shot is enabled
	one_shot = true
	
	# Start emitting particles immediately
	emitting = true
	
	# Connect to the finished signal
	finished.connect(_on_emission_finished)

func _on_emission_finished():
	# Wait a moment to ensure all particles have completed their lifetime
	# before removing the node from the scene
	await get_tree().create_timer(cleanup_delay).timeout
	queue_free()
