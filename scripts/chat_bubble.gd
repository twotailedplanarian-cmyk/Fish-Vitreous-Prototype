@tool
class_name ChatBubble
extends HBoxContainer

@onready var text_label: Label = %text
@onready var speaker_label: Label = %SpeakerLabel
@onready var panel_container: PanelContainer = %PanelContainer
@onready var bubble: VBoxContainer = %bubble
@onready var text_box: Label = %text


@export var speaker_name: String = "":
	set(value):
		speaker_name = value
		if speaker_label:
			speaker_label.text = value

#Stores values for chat bubble styles
@export_enum("other", "self", "fish", "vitriol", "ocean", "self_expanded") var style: String = "other":
	set(new_val):
		style = new_val
		if Engine.is_editor_hint() and is_node_ready():
			change_style()

@export var text: String = "placeholder message":
	set(value):
		text = value
		if Engine.is_editor_hint() and is_node_ready():
			text_label.text = text

var typing_speed: float = 60
var typing_time: float
var tween: Tween

signal finished()

func _ready() -> void:
	change_style()
	text_label.text = text
	speaker_label.text = speaker_name
	if speaker_name == null:
		style = "self_UI"
	reset_size()

#Sets rules for bubble styles and controls how they are called
func change_style() -> void:
	var box = load("res://styles/chat_bubble_%s.tres" % style)
	%PanelContainer.add_theme_stylebox_override("panel", box)
	
	bubble.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN | Control.SIZE_EXPAND
	if style == "self":
		bubble.size_flags_horizontal = Control.SIZE_SHRINK_END | Control.SIZE_EXPAND
		speaker_label.visible = false
	if style == "fish":
		bubble.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN | Control.SIZE_EXPAND
		speaker_label.visible = true
	if style == "vitriol":
		bubble.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN | Control.SIZE_EXPAND
		speaker_label.visible = true
	if style == "vitriol_unlabeled":
		bubble.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN | Control.SIZE_EXPAND
		speaker_label.visible = false
	if style == "ocean":
		bubble.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN | Control.SIZE_EXPAND
		speaker_label.visible = true
	if style == "ocean_unlabled":
		bubble.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN | Control.SIZE_EXPAND
		speaker_label.visible = false
	if style == "self_expanded":
		bubble.size_flags_horizontal = Control.SIZE_SHRINK_END | Control.SIZE_EXPAND
		speaker_label.visible = false
	if style == "other_unlabled":
		bubble.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN | Control.SIZE_EXPAND
		speaker_label.visible = false


func fade(to_color: Color = Color.WHITE, duration: float = 0.3) -> void:
	if tween:
		tween.kill()
	if duration <= 0:
		self.modulate = to_color
		finished.emit()
		return
	tween = create_tween()
	tween.tween_property(self, ^"modulate", to_color, duration)
	tween.finished.connect(_tween_finished, CONNECT_ONE_SHOT)


func fade_in(duration: float = 0.3) -> void:
	self.modulate = Color(1.0, 1.0, 1.0, 0.0)
	fade(Color.WHITE, duration)


func fade_out(duration: float = 0.3) -> void:
	fade(Color(1.0, 1.0, 1.0, 0.0), duration)


func _tween_finished() -> void:
	finished.emit()
