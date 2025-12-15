extends Control

@onready var retry_button: Button = $VBoxContainer/RetryBtn
@onready var quit_button: Button = $VBoxContainer/QuitBtn
@onready var anim_player: AnimationPlayer = $AnimationPlayer 

func _ready() -> void:
	retry_button.pressed.connect(_on_retry_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	retry_button.disabled = true
	quit_button.disabled = true
	anim_player.play("transition")
	retry_button.disabled = false
	quit_button.disabled = false

func _on_retry_pressed() -> void:
	GameManager.reset_to_menu()
	get_tree().change_scene_to_file("res://Screens/game_screen.tscn")

func _on_quit_pressed() -> void:
	GameManager.reset_to_menu()
	get_tree().change_scene_to_file("res://Screens/main_menu.tscn")
