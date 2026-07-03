extends Control

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var animatic: AnimatedSprite2D = $Animatic

@onready var messages: VBoxContainer = %messages
@onready var options_container: VBoxContainer = %options_container
@onready var messages_scroll: ScrollContainer = %messages_scroll

@onready var countdown: Label = %Countdown
@onready var chat_timer: Timer = $ChatTimer
@onready var total_time_seconds: int = 1260

@export var dialogue: DialogueResource
@export var bubble_scene: PackedScene
@export var start_dialogue_title: String
@export var option_button: PackedScene

var quiz_game = load("res://scenes/quiz_game.tscn")

var current_line: DialogueLine
var awaiting_response = false
var current_response: DialogueResponse

var dialogue_freeze = false

var last_speaker = ""

var last_message_text := ""
var last_message_speaker := ""
var last_pushed_line = null
var auto_advance_task_running := false

func _ready() -> void:
	#s
	Global.register_chat(self)
	#s
	#Selects dialogue to use
	start_dialogue_title = "hyoids"
	countdown.text = ""
	await get_tree().process_frame
	if Global.next_dialogue_id != "":
		await push_next_block(Global.next_dialogue_id)
		Global.next_dialogue_id = ""  # clear after use
	else:
		await push_next_block(start_dialogue_title)
	# Start auto‑advance loop if needed
	if not auto_advance_task_running:
		auto_advance_task_running = true
		await auto_advance_loop()

	#if dialogue:
		#await push_next_block(start_dialogue_title)
		#if not auto_advance_task_running:
			#auto_advance_task_running = true
			#await auto_advance_loop()

func start_timer(seconds)-> void:
	total_time_seconds = seconds
	chat_timer.start()

#Controls when dialogue advances
func auto_advance_loop() -> void:
	while is_inside_tree() and auto_advance_task_running:
		if dialogue_freeze:
			await get_tree().process_frame
			continue
		if awaiting_response:
			auto_advance_task_running = false
			return
		var advanced: bool = await get_next_line()
		if not advanced:
			await get_tree().process_frame
			continue
		await push_message()

#Pushes dialogue bubbles if responses aren't being awaited or if the dialogue isn't frozen
func advance_dialogue() -> void:
	if awaiting_response or dialogue_freeze:
		return
	var advanced: bool = await get_next_line()
	if advanced:
		await push_message()

func push_next_block(line_id: String) -> void:
	current_line = await dialogue.get_next_dialogue_line(line_id)
	while current_line:
		await push_message(current_line.text)
		if current_line.responses:
			show_options(current_line.responses)
			awaiting_response = true
			return
		var next_line = await dialogue.get_next_dialogue_line(current_line.next_id)
		if not next_line == current_line:
			break
		current_line = next_line

func get_next_line(start: bool = false) -> bool:
	var next_line: DialogueLine = null
	if current_response:
		next_line = await dialogue.get_next_dialogue_line(current_response.next_id)
		current_response = null
	elif current_line:
		next_line = await dialogue.get_next_dialogue_line(current_line.next_id)
	elif start:
		next_line = await dialogue.get_next_dialogue_line(start_dialogue_title)
	if not next_line or next_line == current_line:
		return false
	current_line = next_line
	return true

func push_message(text: String = "", style: String = "other") -> void:
	#Prevents lines from skipping
	if not current_line:
		awaiting_response = false
		return
	var message_text = text if text != "" else current_line.text
	#var speaker = speaker_style
	var speaker_name = current_line.character
	
	#s
	#Changes bubble style based on the speaker's name
	var speaker_style := style
	if speaker_style != "self":
		match speaker_name:
			"Vitriol":
				speaker_style = "vitriol"
			"VitriolUnlabled":
				speaker_style = "vitriol_unlabeled"
			"Sea":
				speaker_style = "ocean"
			"SeaUnlabled":
				speaker_style = "ocean_unlabled"
			"You":
				speaker_style = "self_expanded"
			_:
				speaker_style = "other"
	var speaker := speaker_style
	#s
	
	if message_text == last_message_text and speaker == last_message_speaker and last_pushed_line == current_line:
		return
	#Delay between messages appearing
	var min_total_delay = 1.8
	var max_total_delay = 1.8
	var computed_total = clamp(message_text.length() * 0.08, min_total_delay, max_total_delay)
	if speaker != "self" and speaker == last_speaker:
		computed_total += 0.8
	#Instantiates chat bubble scene
	if message_text:
		var bubble = bubble_scene.instantiate()
		bubble.style = speaker_style
		bubble.text = message_text
		bubble.speaker_name = speaker_name
		messages.add_child(bubble)
		await scroll_maximum()
	last_speaker = speaker
	last_message_text = message_text
	last_message_speaker = speaker
	last_pushed_line = current_line
	if current_line.responses:
		show_options(current_line.responses)
		awaiting_response = true
		return
	var tree := get_tree()
	if tree == null:
		return
	await get_tree().create_timer(computed_total).timeout
	if not auto_advance_task_running and not awaiting_response and not dialogue_freeze:
		auto_advance_task_running = true
		await auto_advance_loop()
	#messages_scroll.scroll_vertical = 999999999

#Scrolls to bottom of dialogue
func scroll_maximum() -> void:
	var tree := get_tree()
	if tree == null:
		return
	#s
	await get_tree().process_frame
	#s
	await get_tree().process_frame
	if !is_inside_tree():
		return
	var vbar = messages_scroll.get_v_scroll_bar()
	#s
	if vbar:
		messages_scroll.scroll_vertical = vbar.max_value
	#s

#Options appear when the dialogue prompts them
func show_options(options: Array[DialogueResponse]) -> void:
	clear_options()
	for opt in options:
		var ins = option_button.instantiate()
		ins.text = opt.text
		ins.visible = true
		ins.response = opt
		options_container.add_child(ins)
		(ins as Button).pressed.connect(option_pressed.bind(ins))

#Options disappear after clicking
func clear_options() -> void:
	for child in options_container.get_children():
		child.queue_free()

#Moves dialogue when an option is pressed
func option_pressed(button: ChatOptionButton) -> void:
	if dialogue_freeze:
		return
	var response = button.response
	await push_message(button.response.text, "self")
	awaiting_response = false
	current_response = response
	clear_options()
	var reply_delay := 1.5
	await get_tree().create_timer(reply_delay).timeout
	advance_dialogue()

#func _input(event: InputEvent) -> void:
	#if event is InputEventMouseButton:
		#if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
			#if not awaiting_response and not dialogue_freeze:
				#advance_dialogue()

#func _input(event: InputEvent) -> void:
	#if not awaiting_response:
		#await get_tree().create_timer(1).timeout
		#get_next_line()
		#push_message()
		#return

#Change animations
func change_animatic_animation(sprite_frames):
	animatic.play(sprite_frames)

#Timers
func wait_time(seconds: float):
	dialogue_freeze = true
	await get_tree().create_timer(seconds).timeout
	dialogue_freeze = false

#Controls visible timer that shows up during long wait times
func _on_chat_timer_timeout() -> void:
	total_time_seconds -= 1
	var m = int(total_time_seconds / 60)
	var s = total_time_seconds - m * 60
	countdown.text = "%02d:%02d" % [m, s]
	if total_time_seconds < 0:
		chat_timer.stop()
		countdown.text = ""

#s
#Prevents chat from duplicating
func stop_all_dialogue_tasks():
	auto_advance_task_running = false
	dialogue_freeze = true
	awaiting_response = false
	current_line = null
	current_response = null
#s


#func start_quiz():
	#stop_all_dialogue_tasks()
	#await get_tree().process_frame
	#get_tree().change_scene_to_packed(quiz_game)
