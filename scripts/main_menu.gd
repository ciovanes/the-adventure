extends Control

@onready var start_button = $StartButton

func _on_start_button_button_down() -> void:
	get_tree().change_scene_to_file("res://scenes/map/main_map.tscn")
