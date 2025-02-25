extends CanvasLayer 


func _on_play_again_button_down() -> void:
	get_tree().change_scene_to_file("res://scenes/map/main_map.tscn")


func _on_main_menu_button_down() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
