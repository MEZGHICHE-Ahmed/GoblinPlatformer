extends CharacterBody2D

@export var SPEED = 80.0
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var ray_cast: RayCast2D = $RayCast2D
@onready var ray_cast2: RayCast2D = $RayCast2D2

var direction = 1

func _ready() -> void:
	add_to_group("enemies")

func _physics_process(delta: float) -> void:
	if ray_cast.is_colliding():
		direction = -1
	if ray_cast2.is_colliding():
		direction = 1

	if is_on_floor():
		velocity.x = direction * SPEED
		animated_sprite_2d.play("run")
	else:
		velocity += get_gravity() * delta

	if direction == 1:
		animated_sprite_2d.flip_h = false
	else:
		animated_sprite_2d.flip_h = true

	move_and_slide()

func _on_body_entered(body):
	if body.is_in_group("player"):  # If the enemy collides with the player
		body.take_hit()  # Trigger got_hit animation on the player
