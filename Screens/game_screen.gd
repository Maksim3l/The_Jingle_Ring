extends Node2D

## GameScreen - Main fight controller
## Handles enemy spawning, fight flow, UI updates, and game state

signal fight_started(enemy_name: String)
signal fight_ended(enemy_name: String, player_won: bool)
signal all_fights_complete

# Enemy scenes to spawn in order
@export var enemy_scenes: Array[PackedScene] = []
@export var auto_start: bool = true  # Set false if you want to trigger start_game() manually

# Node references
@onready var player: Player = $Player
@onready var enemy_spawn_point: Marker2D = $Entities/EnemySpawnPoint
@onready var ui_layer: CanvasLayer = $UILayer
@onready var health_display: Control = $UILayer/HealthDisplay
@onready var score_display: Control = $UILayer/ScoreDisplay
@onready var pause_menu: Control = $UILayer/PauseMenu
@onready var controls_popup: Control = $UILayer/ControlsPopup

# Current fight state
var current_enemy: Enemy = null
var current_enemy_index: int = 0
var is_fight_active: bool = false

# Enemy scene paths (set these in the editor or here)
const ENEMY_PATHS := [
	"res://Entity/Enemies/Wham.tscn",
	"res://Entity/Enemies/Pariah.tscn"
]


func _ready() -> void:
	# Connect to GameManager signals
	GameManager.game_state_changed.connect(_on_game_state_changed)
	GameManager.player_died.connect(_on_player_died)
	GameManager.hp_changed.connect(_on_hp_changed)
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.combo_changed.connect(_on_combo_changed)
	GameManager.stars_changed.connect(_on_stars_changed)
	
	# Load enemy scenes if not set in editor
	if enemy_scenes.is_empty():
		_load_enemy_scenes()
	
	# Setup UI
	_setup_ui()
	
	# Setup pause input
	set_process_unhandled_input(true)
	
	# Position player
	if player:
		var player_marker = $Entities/PlayerPosition
		if player_marker:
			player.position = player_marker.position
		else:
			player.position = Vector2(320, 280)
	
	# Auto-start the game if enabled (shows controls first)
	if auto_start:
		call_deferred("_show_controls_popup")


func _unhandled_input(event: InputEvent) -> void:
	# Handle controls popup dismissal with any attack button
	if controls_popup and controls_popup.visible:
		if event.is_action_pressed("attack_light") or \
		   event.is_action_pressed("attack_heavy") or \
		   event.is_action_pressed("ui_accept"):
			_on_controls_dismissed()
			get_viewport().set_input_as_handled()
			return
	
	if event.is_action_pressed("pause"):
		GameManager.toggle_pause()


func _show_controls_popup() -> void:
	"""Shows the controls popup before starting the game."""
	if controls_popup:
		controls_popup.visible = true
		# Connect the start button
		var start_btn = controls_popup.get_node_or_null("Panel/MarginContainer/VBoxContainer/StartButton")
		if start_btn and not start_btn.pressed.is_connected(_on_controls_dismissed):
			start_btn.pressed.connect(_on_controls_dismissed)
	else:
		# No popup, just start
		start_game()


func _on_controls_dismissed() -> void:
	"""Called when player dismisses the controls popup."""
	if controls_popup:
		controls_popup.visible = false
	start_game()


func _load_enemy_scenes() -> void:
	for path in ENEMY_PATHS:
		if ResourceLoader.exists(path):
			var scene = load(path)
			if scene:
				enemy_scenes.append(scene)
				print("Loaded enemy: " + path)
			else:
				push_warning("Failed to load enemy scene: " + path)
		else:
			push_warning("Enemy scene file not found: " + path)


# ===== GAME FLOW =====

func start_game() -> void:
	"""Call this to begin the game (after intro/difficulty select)."""
	current_enemy_index = 0
	GameManager.start_game()
	
	print("Game started! Enemy scenes loaded: " + str(enemy_scenes.size()))
	
	# Short delay then spawn first enemy
	await get_tree().create_timer(0.5).timeout
	spawn_next_enemy()


func spawn_next_enemy() -> void:
	"""Spawns the next enemy in the sequence."""
	if enemy_scenes.is_empty():
		push_error("No enemy scenes loaded! Check ENEMY_PATHS or assign in editor.")
		return
	
	if current_enemy_index >= enemy_scenes.size():
		# All enemies defeated!
		_on_all_enemies_defeated()
		return
	
	# Remove current enemy if exists
	if current_enemy and is_instance_valid(current_enemy):
		current_enemy.queue_free()
	
	# Spawn new enemy
	var enemy_scene = enemy_scenes[current_enemy_index]
	current_enemy = enemy_scene.instantiate()
	
	# Position at spawn point
	if enemy_spawn_point:
		current_enemy.position = enemy_spawn_point.position
	else:
		current_enemy.position = Vector2(320, 100)  # Default position
	
	# Add to scene
	$Entities.add_child(current_enemy)
	
	# Connect enemy signals
	if current_enemy.has_signal("died"):
		current_enemy.died.connect(_on_enemy_died)
	if current_enemy.has_signal("phase_changed"):
		current_enemy.phase_changed.connect(_on_enemy_phase_changed)
	
	# Start the fight
	is_fight_active = true
	fight_started.emit(current_enemy.name)
	
	# Initialize enemy state machine
	if current_enemy.has_node("StateMachine"):
		var sm = current_enemy.get_node("StateMachine")
		if sm.has_method("change_state"):
			sm.change_state("IdleState")
	
	print("Fight started: " + current_enemy.name)


func _on_enemy_died() -> void:
	"""Called when current enemy is defeated."""
	is_fight_active = false
	fight_ended.emit(current_enemy.name, true)
	
	current_enemy_index += 1
	
	# Delay before next enemy
	await get_tree().create_timer(2.0).timeout
	
	if GameManager.game_state == GameManager.GameState.PLAYING:
		spawn_next_enemy()


func _on_enemy_phase_changed(new_phase: int) -> void:
	"""Called when enemy enters a new phase."""
	print(current_enemy.name + " entered phase " + str(new_phase))


func _on_all_enemies_defeated() -> void:
	"""Called when all enemies are beaten."""
	all_fights_complete.emit()
	GameManager.trigger_victory()


func _on_player_died() -> void:
	"""Called when player HP reaches 0."""
	is_fight_active = false


# ===== UI UPDATES =====

func _setup_ui() -> void:
	"""Initialize UI components."""
	_on_hp_changed(GameManager.current_hp, GameManager.max_hp)
	_on_score_changed(GameManager.score)
	_on_combo_changed(GameManager.combo)
	_on_stars_changed(GameManager.stars)
	
	if pause_menu:
		pause_menu.visible = false


func _on_hp_changed(current: int, maximum: int) -> void:
	if health_display and health_display.has_method("update_health"):
		health_display.update_health(current, maximum)


func _on_score_changed(new_score: int) -> void:
	if score_display and score_display.has_method("update_score"):
		score_display.update_score(new_score)


func _on_combo_changed(new_combo: int) -> void:
	if score_display and score_display.has_method("update_combo"):
		score_display.update_combo(new_combo)


func _on_stars_changed(new_stars: int) -> void:
	if health_display and health_display.has_method("update_stars"):
		health_display.update_stars(new_stars)


func _on_game_state_changed(new_state: GameManager.GameState) -> void:
	match new_state:
		GameManager.GameState.PAUSED:
			_show_pause_menu()
		GameManager.GameState.PLAYING:
			_hide_pause_menu()
		GameManager.GameState.GAME_OVER:
			_show_game_over()
		GameManager.GameState.VICTORY:
			_show_victory()


func _show_pause_menu() -> void:
	if pause_menu:
		pause_menu.visible = true


func _hide_pause_menu() -> void:
	if pause_menu:
		pause_menu.visible = false


func _show_game_over() -> void:
	print("GAME OVER")
	get_tree().change_scene_to_file("res://Screens/game_over_screen.tscn")


func _show_victory() -> void:
	print("VICTORY!")
	var stats = GameManager.get_final_stats()
	print("Final Score: ", stats.score)
	print("Rating: ", stats.rating)
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://Screens/victory.tscn")


# ===== UTILITY =====

func get_current_enemy() -> Enemy:
	return current_enemy


func restart_fight() -> void:
	GameManager.start_game()
	spawn_next_enemy()
