extends Control

## PauseMenu - Shown when game is paused

signal resume_pressed
signal quit_pressed

@export var title_font: Font
@export var button_font: Font

var panel: Panel
var title_label: Label
var resume_button: Button
var quit_button: Button


func _ready() -> void:
	_setup_ui()
	
	# This control should block input when visible
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Pause menu should work even when tree is paused
	process_mode = Node.PROCESS_MODE_ALWAYS


func _setup_ui() -> void:
	# Full screen semi-transparent background
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	
	# Center panel
	panel = Panel.new()
	panel.custom_minimum_size = Vector2(200, 250)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -100
	panel.offset_right = 100
	panel.offset_top = -125
	panel.offset_bottom = 125
	add_child(panel)
	
	# VBox for content
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20
	vbox.offset_right = -20
	vbox.offset_top = 20
	vbox.offset_bottom = -20
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)
	
	# Title
	title_label = Label.new()
	title_label.text = "PAUSED"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if title_font:
		title_label.add_theme_font_override("font", title_font)
	title_label.add_theme_font_size_override("font_size", 32)
	vbox.add_child(title_label)
	
	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)
	
	# Resume button
	resume_button = Button.new()
	resume_button.text = "Resume"
	resume_button.custom_minimum_size = Vector2(140, 40)
	if button_font:
		resume_button.add_theme_font_override("font", button_font)
	resume_button.pressed.connect(_on_resume_pressed)
	vbox.add_child(resume_button)
	
	# Quit button
	quit_button = Button.new()
	quit_button.text = "Quit to Menu"
	quit_button.custom_minimum_size = Vector2(140, 40)
	if button_font:
		quit_button.add_theme_font_override("font", button_font)
	quit_button.pressed.connect(_on_quit_pressed)
	vbox.add_child(quit_button)


func _on_resume_pressed() -> void:
	GameManager.resume_game()
	resume_pressed.emit()

func _on_quit_pressed() -> void:
	GameManager.reset_to_menu()
	quit_pressed.emit()
	ScreenManager.transition_to("res://Screens/main_menu.tscn")


func _input(event: InputEvent) -> void:
	# Allow unpausing with escape or pause button
	if visible and event.is_action_pressed("pause"):
		_on_resume_pressed()
		get_viewport().set_input_as_handled()
