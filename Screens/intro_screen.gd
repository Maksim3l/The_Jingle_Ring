extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var story_label: RichTextLabel = $OverlayLayer/StoryText

@export_multiline var story_text: String = "
An ancient and insidious power...
[color=#949aa3][s]Mariah Carey[/s][/color]... Pariah Scary... seeks to ruin every Christmas 
by taking over the spirit of the season 
with the power of her overdone music!
And there's only one way to save Christmas...
STOP HER BEFORE WINTER COMES WITH
[color=#a01616]VIOLENCE![/color]"

@export var char_delay: float = 0.1
@export var line_pause_before: float = 1.0
@export var line_pause_after: float = 1.5
@export var punctuation_pause: float = 0.2

var _lines: PackedStringArray
var _current_line: int = 0
var _current_index: int = 0
var _typing: bool = false
var _can_skip: bool = true


func _ready() -> void:
	story_label.bbcode_enabled = true
	story_label.text = ""
	_start_typewriter()


func _start_typewriter() -> void:
	_lines = story_text.split("\n")
	_current_line = 0
	_typing = true
	_type_line()


func _type_line() -> void:
	if _current_line >= _lines.size():
		_typing = false
		_on_typewriter_finished()
		return
	
	story_label.text = ""
	_current_index = 0
	_type_next_char()


func _type_next_char() -> void:
	if not _typing:
		return
	
	var line := _lines[_current_line]
	
	if _current_index >= line.length():
		_current_line += 1
		if _current_line < _lines.size():
			await get_tree().create_timer(line_pause_after).timeout
			if _typing:
				await get_tree().create_timer(line_pause_before).timeout
				if _typing:
					_type_line()
		else:
			_typing = false
			_on_typewriter_finished()
		return
	
	var c := line[_current_index]
	story_label.text += c
	_current_index += 1
	
	# Skip delay for BBCode tag characters
	if c == "[" or _in_bbcode_tag(line, _current_index):
		_type_next_char()
		return
	
	var delay := char_delay
	if c in [".", "!", "?", ":"]:
		delay = punctuation_pause
	elif c == ",":
		delay = punctuation_pause * 0.5
	
	get_tree().create_timer(delay).timeout.connect(_type_next_char)


func _in_bbcode_tag(line: String, idx: int) -> bool:
	var last_open := line.rfind("[", idx - 1)
	var last_close := line.rfind("]", idx - 1)
	return last_open > last_close


func _on_typewriter_finished() -> void:
	await get_tree().create_timer(1.5).timeout
	story_label.hide()
	animation_player.play("intro_sequence")
	animation_player.animation_finished.connect(_on_animation_finished)


func _on_animation_finished(_anim_name: String) -> void:
	_go_to_game()


func _go_to_game() -> void:
	_can_skip = false
	get_tree().change_scene_to_file("res://Screens/game_screen.tscn")


func _input(event: InputEvent) -> void:
	if not _can_skip:
		return
	
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		if _typing:
			_typing = false
			story_label.text = _lines[_lines.size() - 1]
			_on_typewriter_finished()
		else:
			animation_player.stop()
			_go_to_game()
