extends Node3D


func _input(event: InputEvent) -> void:
	if event.is_action("quit"):
		get_tree().quit()
