extends Control

@onready var ranking_label: Label = $RankingLabel
@onready var score_label: Label = $LeftContainer/ScoreLabel
@onready var retry_button: Button = $LeftContainer/RetryBtn
@onready var quit_button: Button = $LeftContainer/QuitBtn
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var snowflake_strip: TextureRect = $SnowflakeStrip
@export var music_filename: String = "victory.wav" 

var ranking_tween: Tween
var snowflake_offset: float = 0.0


func _ready() -> void:
	# Get stats
	var stats = GameManager.get_final_stats()
	
	# Set labels
	ranking_label.text = stats.rating
	ranking_label.add_theme_color_override("font_color", _get_rating_color(stats.rating))
	score_label.text = "Score: " + str(stats.score)
	
	# Connect buttons
	retry_button.pressed.connect(_on_retry_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Play transition, then victory
	var player = AudioStreamPlayer.new()
	player.bus = "Music"
	add_child(player)
	
	var path = "res://Assets/Audio/" + music_filename
	if ResourceLoader.exists(path):
		player.stream = load(path)
		player.play()
	
	anim_player.play("transition")
	anim_player.animation_finished.connect(_on_animation_finished)
	
	# Start ranking pulsate
	_start_ranking_animation()


func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "transition":
		anim_player.play("victory")


func _start_ranking_animation() -> void:
	ranking_tween = create_tween()
	ranking_tween.set_loops()
	
	ranking_tween.tween_property(ranking_label, "scale", Vector2(1.1, 1.1), 0.5)
	ranking_tween.parallel().tween_property(ranking_label, "rotation_degrees", 5.0, 0.5)
	
	ranking_tween.tween_property(ranking_label, "scale", Vector2(1.0, 1.0), 0.5)
	ranking_tween.parallel().tween_property(ranking_label, "rotation_degrees", -5.0, 0.5)
	
	ranking_tween.tween_property(ranking_label, "rotation_degrees", 0.0, 0.25)


func _process(delta: float) -> void:
	if snowflake_strip and snowflake_strip.texture:
		snowflake_offset += delta * 30.0
		snowflake_strip.position.x = -fmod(snowflake_offset, snowflake_strip.texture.get_width())


func _get_rating_color(rating: String) -> Color:
	match rating:
		"SSS", "SS", "S":
			return Color.GOLD
		"A":
			return Color.GREEN
		"B":
			return Color.CYAN
		"C":
			return Color.WHITE
		_:
			return Color.GRAY


func _on_retry_pressed() -> void:
	if ranking_tween:
		ranking_tween.kill()
	GameManager.reset_to_menu()
	get_tree().change_scene_to_file("res://Screens/game_screen.tscn")


func _on_quit_pressed() -> void:
	if ranking_tween:
		ranking_tween.kill()
	GameManager.reset_to_menu()
	get_tree().change_scene_to_file("res://Screens/main_menu.tscn")
