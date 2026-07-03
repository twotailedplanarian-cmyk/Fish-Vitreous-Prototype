extends Control

#@onready var option_1: Button = $VBoxContainer/Options/Option1
#@onready var option_2: Button = $VBoxContainer/Options/Option2
#@onready var option_3: Button = $VBoxContainer/Options/Option3
#@onready var option_4: Button = $VBoxContainer/Options/Option4
#
#@onready var score: Label = $Score

var main_scene = load("res://scenes/chat.tscn")

@onready var click_animation: AnimatedSprite2D = $ClickAnimation

@export var quiz: QuizTheme
@export var color_right: Color
@export var color_wrong: Color

@onready var score: Label = $Score

@onready var audio_incorrect: AudioStreamPlayer2D = $AudioIncorrect
@onready var audio_correct: AudioStreamPlayer2D = $AudioCorrect

var buttons: Array[Button]
var index: int
var correct: int
var points = 0

var current_quiz: QuizQuestion:
	get: return quiz.theme[index]

@onready var question_image: TextureRect = $VBoxContainer/QuestionImage

func _ready() -> void:
	correct = 0
	for button in $VBoxContainer/Options.get_children():
		buttons.append(button)
	load_quiz()

func load_quiz() -> void:
	if index >= quiz.theme.size():
		_game_over()
		return
	question_image.texture = current_quiz.question_image
	var options = current_quiz.options
	for i in buttons.size():
		buttons[i].text = options[i]
		buttons[i].pressed.connect(_buttons_answer.bind(buttons[i]))
	
	match current_quiz.type:
		Enum.QuestionType.TEXT:
			pass
			#can hide content holders here
		Enum.QuestionType.IMAGE:
			question_image.texture = current_quiz.question_image
		Enum.QuestionType.VIDEO:
			pass
		Enum.QuestionType.AUDIO:
			pass

func _buttons_answer(button) -> void:
	click_animation.play("default")
	if current_quiz.correct == button.text:
		button.modulate = color_right
		points += 100
		print(points)
		audio_correct.play()
	else:
		button.modulate = color_wrong
		audio_incorrect.play()
		print(points)
	_next_question()

func _next_question() -> void:
	for bt in buttons:
		bt.pressed.disconnect(_buttons_answer)
	await get_tree().create_timer(1).timeout
	for bt in buttons:
		bt.modulate = Color.WHITE
	
	#question_audio.stop()
	#question_video.stop
	#question_audio.stream = null
	#question_video.stream = null
	
	index += 1
	load_quiz()

func _game_over() -> void:
	$GameOver.show()
	$GameOver/VBoxContainer/FinalPoints.text = str(points, "/", quiz.theme.size() * 100)
	if points >= (quiz.theme.size() * 100)/2:
		$GameOver/VBoxContainer/FinalAssessment.text = str("Assessment: PASS")
		Global.quiz_passed = true
	else:
		$GameOver/VBoxContainer/FinalAssessment.text = str("Assessment: FAIL")
		Global.quiz_passed = false


func _on_return_button_pressed() -> void:
	#get_tree().change_scene_to_packed(main_scene)
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	get_tree().change_scene_to_file("res://scenes/chat.tscn")
