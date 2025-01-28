extends Control

@onready var turn_input: SpinBox = $TurnInput
@onready var confirm: Button = $Confirm

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_confirm_pressed() -> void:
	var num_turns = turn_input.value
	# Store the number of turns in a singleton
	GameSettings.num_turns = num_turns
	# Transition to Main Game Scene
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()
