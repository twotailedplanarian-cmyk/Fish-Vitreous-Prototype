extends Node

#s

var chat_scene: Node = null
var next_dialogue_id: String = ""
var quiz_passed: bool

func register_chat(chat: Node) -> void:
	chat_scene = chat

func change_animatic_animation(sprite_frames: String) -> void:
	#if chat_scene and chat_scene.has_method("change_animatic_animation"):
		#chat_scene.change_animatic_animation(sprite_frames)
	if chat_scene:
		chat_scene.call_deferred("change_animatic_animation", sprite_frames)

func start_quiz() -> void:
	next_dialogue_id = "after_quiz"
	#if chat_scene and chat_scene.current_line:
		#next_dialogue_id = chat_scene.current_line.next_id
	if chat_scene:
		chat_scene.auto_advance_task_running = false
		chat_scene.awaiting_response = false
		chat_scene.dialogue_freeze = true
	get_tree().change_scene_to_file("res://scenes/quiz_game.tscn")

#s

func select_episode(episode_file: String) -> void:
	get_tree().change_scene_to_file(episode_file)

func return_to_scene_select():
	if chat_scene:
		chat_scene.auto_advance_task_running = false
		chat_scene.awaiting_response = false
		chat_scene.dialogue_freeze = true
	get_tree().change_scene_to_file("res://scenes/scene_select.tscn")
