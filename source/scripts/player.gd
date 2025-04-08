extends CharacterBody2D

# Movement Parameters
@export var SPEED = 120.0
@export var SLIDE_SPEED = 200.0
@export var SLIDE_DURATION = 0.5  # Added slide duration
@export var JUMP_VELOCITY = -300.0
@export var FRICTION = 800.0
@export var AIR_RESISTANCE = 400.0

# Combat Parameters
@export var ATTACK_RANGE = 40.0
@export var HIT_RECOVERY_TIME = 0.5

# Dash Parameters
@export var DASH_SPEED = 500.0
@export var DASH_DURATION = 0.2
@export var DASH_COOLDOWN = 1.0
@export var DASH_ATTACK_RANGE = 20.0
@export var TARGET_RADIUS = 200.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_sound: AudioStreamPlayer2D = $AttackSword
@onready var dash_sound: AudioStreamPlayer2D = $DashSound

# State variables
enum {IDLE, RUN, JUMP, SLIDE, ATTACK, DASH, HIT}
var state = IDLE
var attack_count = 0
var was_on_floor = true
var can_dash = true
var dash_timer = 0.0
var target_enemy = null
var facing_direction = 1

func _ready():
	animated_sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	if state == HIT:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	was_on_floor = is_on_floor()
	
	match state:
		DASH:
			_handle_dash(delta)
		ATTACK:
			_handle_attack()
		SLIDE:
			_handle_slide(delta)
		_:
			_handle_normal_movement(delta)
	
	if Input.is_action_just_pressed("dash") and can_dash and state != ATTACK:
		_initiate_dash()
	
	move_and_slide()
	_update_animations()
	
	if not was_on_floor and is_on_floor() and state != DASH:
		state = RUN if abs(velocity.x) > 10 else IDLE

func _handle_normal_movement(delta: float):
	var input_dir = Input.get_axis("move_left", "move_right")
	
	if input_dir != 0:
		velocity.x = input_dir * SPEED
		facing_direction = input_dir
		if is_on_floor():
			state = RUN
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		if is_on_floor() and state != ATTACK:
			state = IDLE
	
	if Input.is_action_just_pressed("jump") and is_on_floor() and state != ATTACK:
		velocity.y = JUMP_VELOCITY
		state = JUMP
	
	if not is_on_floor():
		velocity.y += _get_gravity() * delta
		if state != JUMP and velocity.y > 0:
			state = JUMP
	
	if Input.is_action_just_pressed("slide") and is_on_floor() and abs(velocity.x) > SPEED * 0.5:
		_start_slide()
	
	if Input.is_action_just_pressed("attack") and is_on_floor() and state != ATTACK:
		_start_attack()

func _handle_dash(delta: float):
	dash_timer += delta
	
	if target_enemy and is_instance_valid(target_enemy):
		var predicted_position = _predict_enemy_position(target_enemy)
		var new_direction = (predicted_position - global_position).normalized()
		velocity = new_direction * DASH_SPEED
		
		if global_position.distance_to(target_enemy.global_position) <= DASH_ATTACK_RANGE:
			_perform_dash_attack(target_enemy)
			return
	
	if dash_timer >= DASH_DURATION:
		_end_dash()

func _handle_attack():
	_check_enemy_hit()

func _handle_slide(delta: float):
	velocity.x = facing_direction * SLIDE_SPEED
	
	if Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY
		state = JUMP
	
	if not is_on_floor():
		state = JUMP

func _start_slide():
	state = SLIDE
	velocity.x = facing_direction * SLIDE_SPEED
	animated_sprite.play("slide")
	
	# Slide duration timer
	await get_tree().create_timer(SLIDE_DURATION).timeout
	if state == SLIDE:  # Only transition if still sliding
		state = RUN if abs(velocity.x) > 10 else IDLE
		velocity.x = facing_direction * SPEED  # Reset to normal speed

func _start_attack():
	state = ATTACK
	attack_count = (attack_count % 3) + 1
	animated_sprite.play("attack" + str(attack_count))
	attack_sound.play()
	_check_enemy_hit()

func _get_gravity() -> float:
	return ProjectSettings.get_setting("physics/2d/default_gravity")

func _predict_enemy_position(enemy) -> Vector2:
	var enemy_velocity = enemy.velocity if enemy.has_method("get_velocity") else Vector2.ZERO
	var time_remaining = DASH_DURATION - dash_timer
	return enemy.global_position + enemy_velocity * time_remaining

func _perform_dash_attack(enemy):
	state = ATTACK
	attack_count = (attack_count % 3) + 1
	animated_sprite.play("attack" + str(attack_count))
	attack_sound.play()

	# Spawn explosion at enemy position
	var explosion_scene = preload("res://scenes/explosion.tscn")
	var explosion_instance = explosion_scene.instantiate()
	get_tree().current_scene.add_child(explosion_instance)
	explosion_instance.global_position = enemy.global_position

	# Hide enemy immediately but defer freeing it
	var camera = get_tree().get_first_node_in_group("camera")
	if camera:
		camera.shake_camera(0.4)
	enemy.visible = false
	enemy.queue_free()

	velocity *= 0.3
	
	# End dash and start cooldown
	_end_dash()

func _initiate_dash():
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest_enemy = null
	var closest_distance = TARGET_RADIUS
	
	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance <= TARGET_RADIUS and distance < closest_distance:
			closest_enemy = enemy
			closest_distance = distance
	
	state = DASH
	can_dash = false
	dash_timer = 0.0
	target_enemy = closest_enemy
	
	if target_enemy:
		var predicted_pos = _predict_enemy_position(target_enemy)
		velocity = (predicted_pos - global_position).normalized() * DASH_SPEED
	else:
		velocity = Vector2(facing_direction, 0) * DASH_SPEED
	
	animated_sprite.play("dash_air")


func _end_dash():
	state = IDLE
	target_enemy = null
	velocity = velocity.normalized() * SPEED
	await get_tree().create_timer(DASH_COOLDOWN).timeout
	can_dash = true

func _check_enemy_hit():
	var attack_dir = Vector2(-1 if animated_sprite.flip_h else 1, 0)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var dir_to_enemy = (enemy.global_position - global_position).normalized()
		if global_position.distance_to(enemy.global_position) <= ATTACK_RANGE and dir_to_enemy.dot(attack_dir) > 0.7:
			var explosion_scene = preload("res://scenes/explosion.tscn")
			var explosion_instance = explosion_scene.instantiate()
			get_tree().current_scene.add_child(explosion_instance)
			explosion_instance.global_position = enemy.global_position
			enemy.queue_free()

func _update_animations():
	animated_sprite.flip_h = facing_direction < 0
	match state:
		DASH:
			animated_sprite.play("dash_air")
		ATTACK:
			pass
		JUMP:
			animated_sprite.play("jump")
		SLIDE:
			animated_sprite.play("slide")
		RUN:
			animated_sprite.play("run")
		IDLE:
			animated_sprite.play("idle")
		HIT:
			animated_sprite.play("hit")

func _on_animation_finished():
	if animated_sprite.animation.begins_with("attack"):
		if state == ATTACK:
			state = IDLE
	elif animated_sprite.animation == "dash_air" and state == DASH:
		animated_sprite.play("dash_air")

func take_hit(death: bool = false):
	if state == HIT: return
	state = HIT
	velocity = Vector2.ZERO
	if death:
		get_tree().reload_current_scene()
	else:
		await get_tree().create_timer(HIT_RECOVERY_TIME).timeout
		state = IDLE
