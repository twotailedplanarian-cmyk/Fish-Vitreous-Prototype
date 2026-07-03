extends Control

@onready var panel_container: PanelContainer = $PanelContainer
@onready var credits: Button = $Credits
@onready var exit_credits: Button = $PanelContainer/MarginContainer/VBoxContainer/ExitCredits



func _on_credits_pressed() -> void:
	SfxManager.play_sfx_button()
	panel_container.visible = true

func _on_exit_credits_pressed() -> void:
	SfxManager.play_sfx_button()
	panel_container.visible = false
