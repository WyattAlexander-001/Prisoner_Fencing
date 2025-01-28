extends Control


@onready var start: Button = $VBoxContainer/Start
@onready var exit: Button = $VBoxContainer/Exit

func _ready() -> void:
	pass

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/setup.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
