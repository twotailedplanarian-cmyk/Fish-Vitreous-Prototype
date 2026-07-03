extends Button

@onready var home_screen: PanelContainer = %HomeScreen


func _on_pressed() -> void:
	home_screen.visible = true
