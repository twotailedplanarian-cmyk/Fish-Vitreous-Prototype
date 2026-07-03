extends Button


func _on_pressed() -> void:
	SfxManager.play_sfx_button()
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	Global.select_episode("res://scenes/title_screen.tscn")
