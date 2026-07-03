class_name ChatBubble
extends HBoxContainer

@onready var text_label: Label = %text
@onready var speaker_label: Label = %SpeakerLabel
@onready var panel_container: PanelContainer = %PanelContainer
@onready var bubble_animation: AnimationPlayer = $BubbleAnimation

var typing_speed: float = 60
var typing_time: float


#AIS
@export var speaker_name: String = "":
	set(value):
		speaker_name = value
		if speaker_label:
			speaker_label.text = value
#AIS

#Stores values for chat bubble styles
@export_enum("other", "self", "fish", "vitriol", "ocean", "self_expanded") var style: String = "other":
	set(new_val):
		style = new_val
		if Engine.is_editor_hint() or is_node_ready():
			change_style()

@export var text: String = "placeholder message"
@onready var text_box: Label = %text


func _ready() -> void:
	change_style()
	text_label.text = text
	speaker_label.text = speaker_name
	if speaker_name == null:
		style = "self_UI"
	text_label.set_custom_minimum_size(Vector2(0,0))

#Sets rules for bubble styles and controls how they are called
func change_style() -> void:
	var box = load("res://styles/chat_bubble_%s.tres" % style)
	%PanelContainer.add_theme_stylebox_override("panel", box)
	alignment = BoxContainer.ALIGNMENT_BEGIN
	if style == "self":
		alignment = BoxContainer.ALIGNMENT_END
		speaker_label.visible = false
	if style == "fish":
		alignment = BoxContainer.ALIGNMENT_BEGIN
		speaker_label.visible = true
	if style == "vitriol":
		alignment = BoxContainer.ALIGNMENT_BEGIN
		speaker_label.visible = true
	if style == "vitriol_unlabeled":
		alignment = BoxContainer.ALIGNMENT_BEGIN
		speaker_label.visible = false
	if style == "ocean":
		alignment = BoxContainer.ALIGNMENT_BEGIN
		speaker_label.visible = true
	if style == "ocean_unlabled":
		alignment = BoxContainer.ALIGNMENT_BEGIN
		speaker_label.visible = false
	if style == "self_expanded":
		alignment = BoxContainer.ALIGNMENT_END
		speaker_label.visible = false
	if style == "other_unlabled":
		alignment = BoxContainer.ALIGNMENT_BEGIN
		speaker_label.visible = false
		
