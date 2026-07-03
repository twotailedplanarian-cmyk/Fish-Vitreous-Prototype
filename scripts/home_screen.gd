extends PanelContainer
@onready var home_screen: PanelContainer = %HomeScreen


func _on_texture_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		home_screen.visible = false

func _on_settings_app_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		get_tree().change_scene_to_file("res://scenes/scene_select.tscn")
