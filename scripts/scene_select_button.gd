extends Button

var scene_select_scene = load("res://scenes/scene_select.tscn")

func _on_pressed() -> void:
	SfxManager.play_sfx_button()
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	get_tree().change_scene_to_file("res://scenes/scene_select.tscn")
	
