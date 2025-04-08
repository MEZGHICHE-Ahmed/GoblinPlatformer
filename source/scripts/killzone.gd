extends Area2D

@onready var timer: Timer = $Timer
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer

func _on_body_entered(body: Node2D) -> void:
	audio.play()
	body.take_hit(true)  # Call take_hit with death = true


func _on_timer_timeout() -> void:
	#engine time back to normal
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()
