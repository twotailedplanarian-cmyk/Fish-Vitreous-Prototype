extends Button

var scene_select_scene = load("res://scenes/hyoids.tscn")

func _on_pressed() -> void:
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	Global.select_episode("res://scenes/hyoids.tscn")
