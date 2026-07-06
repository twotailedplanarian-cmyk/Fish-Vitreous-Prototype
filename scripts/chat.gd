extends Control

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var animatic: AnimatedSprite2D = $Animatic

@onready var messages: VBoxContainer = %messages
@onready var options_container: VBoxContainer = %options_container
@onready var messages_scroll: ScrollContainer = %messages_scroll
@onready var transitions: AnimationPlayer = $Transitions
@onready var black_fade: ColorRect = $BlackFade
@onready var black_fade_sprite: Sprite2D = $BlackFadeSprite
@onready var setting_sprite: Sprite2D = $SettingSprite

@onready var countdown: Label = %Countdown
@onready var chat_timer: Timer = $ChatTimer
@onready var total_time_seconds: int = 1260

@export var dialogue: DialogueResource
@export var bubble_scene: PackedScene
@export var start_dialogue_title: String
@export var option_button: PackedScene

@onready var contact_name_label: Label = %ContactNameLabel
@onready var typing_label: Label = %TypingLabel

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
	black_fade.visible = true
	black_fade.modulate = Color(255, 255, 255, 0)
	#AIS
	Global.register_chat(self)
	#AIS
	start_dialogue_title = "test"
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


#Display sprite to show background
func show_background():
	setting_sprite.visible = true
	await get_tree().create_timer(5).timeout
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	setting_sprite.visible = false
	

#start visible timer
func start_timer(seconds)-> void:
	total_time_seconds = seconds
	chat_timer.start()

#I think this part moves a non-self character's message forward after one was already sent
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

#I think this part checks if the dialogue should be running or not. If it should be, it calls the function to push a message
func advance_dialogue() -> void:
	if awaiting_response or dialogue_freeze:
		return
	var advanced: bool = await get_next_line()
	if advanced:
		await push_message()

#What's the function of pushing a "block" if we're already pushing a message?
#I think it allows the options to show and helps get the dialogue for the next part of the scene
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

#I think this part checks the dialogue script to see if the dialogue or the responses should continue
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
	
	#AIS
	#Changes bubble style based on the speaker's name
	var speaker_style := style
	if speaker_style != "self":
		match speaker_name:
			"Midward":
				speaker_style = "other"
			"You":
				speaker_style = "self"
			_:
				speaker_style = "other"
	var speaker := speaker_style
	#AIS
	
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
		var bubble: ChatBubble = bubble_scene.instantiate()
		bubble.style = speaker_style
		bubble.text = message_text
		bubble.speaker_name = speaker_name
		messages.add_child(bubble)
		bubble.fade_in()
		if speaker == "self" or speaker_name == "You":
			SfxManager.play_sfx_send()
		else:
			SfxManager.play_sfx_button()
		await scroll_maximum()
	# awaits are dangerous especially if we're in the middle of freeing a scene.
	# being aware if we're in the middle of being deleted is important
	if !is_inside_tree():
		return
	last_speaker = speaker
	last_message_text = message_text
	last_message_speaker = speaker
	last_pushed_line = current_line
	if current_line.responses:
		show_options(current_line.responses)
		awaiting_response = true
		return
	typing_label.show()
	await get_tree().create_timer(computed_total).timeout
	typing_label.hide()
	if !is_inside_tree():
		return
	if not auto_advance_task_running and not awaiting_response and not dialogue_freeze:
		auto_advance_task_running = true
		await auto_advance_loop()

var scroll_tween: Tween
func scroll_maximum() -> void:
	if !is_inside_tree():
		return
	await get_tree().process_frame
	if !is_inside_tree():
		return
	if scroll_tween:
		scroll_tween.kill()
	scroll_tween = create_tween()
	var vbar = messages_scroll.get_v_scroll_bar()
	if not vbar:
		return
	var duration: float = 0.4
	scroll_tween.tween_property(messages_scroll, ^"scroll_vertical", vbar.max_value, duration).set_ease(Tween.EASE_OUT)
	await scroll_tween.finished

#Makes options visible
func show_options(options: Array[DialogueResponse]) -> void:
	clear_options()
	for opt in options:
		#Instantiates options
		var ins = option_button.instantiate()
		ins.text = opt.text
		ins.visible = true
		ins.response = opt
		options_container.add_child(ins)
		(ins as Button).pressed.connect(option_pressed.bind(ins))

func clear_options() -> void:
	for child in options_container.get_children():
		child.queue_free()

func set_options_disabled(toggle: bool) -> void:
	for child in options_container.get_children():
		child.disabled = toggle

#Controls option panel
func option_pressed(button: ChatOptionButton) -> void:
	#Prevents options from showing when other character is speaking
	if dialogue_freeze:
		return
	# disable the options so that they're not clickable anymore
	set_options_disabled(true)
	#Sets text for options
	var response = button.response
	#Waits for message to send, then clears the options
	await push_message(button.response.text, "self")
	awaiting_response = false
	current_response = response
	clear_options()
	var reply_delay := 1.5
	typing_label.show()
	await get_tree().create_timer(reply_delay).timeout
	typing_label.hide()
	advance_dialogue()

#Change animations
func change_animatic_animation(sprite_frames):
	animatic.play(sprite_frames)

#Timers
func wait_time(seconds: float):
	dialogue_freeze = true
	await get_tree().create_timer(seconds).timeout
	dialogue_freeze = false

#Transitions within a scene (honestly I can probably get rid of this and just use the "fade_to_black" transition)
func fade_transition():
	transitions.play("fade_in_and_out")

#Transitions between scenes
func fade_to_black():
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished

#Controls visible chat timer
func _on_chat_timer_timeout() -> void:
	total_time_seconds -= 1
	var m = int(total_time_seconds / 60)
	var s = total_time_seconds - m * 60
	countdown.text = "%02d:%02d" % [m, s]
	if total_time_seconds < 0:
		chat_timer.stop()
		countdown.text = ""

#AIS
#Stops all dialogue functions so that the scene can change
func stop_all_dialogue_tasks():
	auto_advance_task_running = false
	dialogue_freeze = true
	awaiting_response = false
	current_line = null
	current_response = null
#AIS
