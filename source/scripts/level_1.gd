extends Node2D

@onready var gamecomplete: Panel = $CanvasLayer/gamecomplete
@onready var audio: AudioStreamPlayer = $gamefinished/AudioStreamPlayer

func _ready() -> void:
	gamecomplete.visible = false
	var camera = $Camera2D  # Adjust path as needed

func _on_restartbutton_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/level_2.tscn")

func _on_gamefinished_body_entered(body: Node2D) -> void:
	audio.play()
	gamecomplete.visible = true
	await get_tree().create_timer(2.0).timeout  # Optional delay to let audio play
	get_tree().change_scene_to_file("res://scenes/levels/level_2.tscn")  # Update with your actual path
