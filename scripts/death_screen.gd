extends CanvasLayer


func _on_play_again_button_down() -> void:
	queue_free()
	get_tree().reload_current_scene()

func _on_main_menu_button_down() -> void:
	queue_free()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
