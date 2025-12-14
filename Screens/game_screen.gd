extends Node2D

## GameScreen - Main fight controller
## Handles enemy spawning, fight flow, UI updates, and game state

signal fight_started(enemy_name: String)
signal fight_ended(enemy_name: String, player_won: bool)
signal all_fights_complete

# Enemy scenes to spawn in order
@export var enemy_scenes: Array[PackedScene] = []

# Node references
@onready var player: Player = $Player
@onready var enemy_spawn_point: Marker2D = $Entities/EnemySpawnPoint
@onready var ui_layer: CanvasLayer = $UILayer
@onready var health_display: Control = $UILayer/HealthDisplay
@onready var score_display: Control = $UILayer/ScoreDisplay
@onready var pause_menu: Control = $UILayer/PauseMenu

# Current fight state
var current_enemy: Enemy = null
var current_enemy_index: int = 0
var is_fight_active: bool = false

# Enemy scene paths (set these in the editor or here)
const ENEMY_PATHS := [
	"res://Entity/Enemies/Wham.tscn",
	"res://Entity/Enemies/Hells.tscn",
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
		player.position = $Entities/PlayerPosition.position if $Entities/PlayerPosition else Vector2(320, 280)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		GameManager.toggle_pause()


func _load_enemy_scenes() -> void:
	for path in ENEMY_PATHS:
		var scene = load(path)
		if scene:
			enemy_scenes.append(scene)
		else:
			push_warning("Failed to load enemy scene: " + path)


# ===== GAME FLOW =====

func start_game() -> void:
	"""Call this to begin the game (after intro/difficulty select)."""
	current_enemy_index = 0
	GameManager.start_game()
	
	# Short delay then spawn first enemy
	await get_tree().create_timer(0.5).timeout
	spawn_next_enemy()


func spawn_next_enemy() -> void:
	"""Spawns the next enemy in the sequence."""
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
	current_enemy.died.connect(_on_enemy_died)
	current_enemy.phase_changed.connect(_on_enemy_phase_changed)
	
	# Start the fight
	is_fight_active = true
	fight_started.emit(current_enemy.name)
	
	# Initialize enemy state machine
	if current_enemy.state_machine:
		current_enemy.state_machine.change_state("IdleState")
	
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
	
	# Could add visual effects, brief pause, etc.
	# Flash the screen or show "Phase 2!" text


func _on_all_enemies_defeated() -> void:
	"""Called when all enemies are beaten."""
	all_fights_complete.emit()
	GameManager.trigger_victory()


func _on_player_died() -> void:
	"""Called when player HP reaches 0."""
	is_fight_active = false
	
	# Player death is handled by player's DieState
	# Game over screen will be shown by UI


# ===== UI UPDATES =====

func _setup_ui() -> void:
	"""Initialize UI components."""
	# Update displays with initial values
	_on_hp_changed(GameManager.current_hp, GameManager.max_hp)
	_on_score_changed(GameManager.score)
	_on_combo_changed(GameManager.combo)
	_on_stars_changed(GameManager.stars)
	
	# Hide pause menu initially
	if pause_menu:
		pause_menu.visible = false


func _on_hp_changed(current: int, maximum: int) -> void:
	"""Update health display."""
	if health_display and health_display.has_method("update_health"):
		health_display.update_health(current, maximum)


func _on_score_changed(new_score: int) -> void:
	"""Update score display."""
	if score_display and score_display.has_method("update_score"):
		score_display.update_score(new_score)


func _on_combo_changed(new_combo: int) -> void:
	"""Update combo display."""
	if score_display and score_display.has_method("update_combo"):
		score_display.update_combo(new_combo)


func _on_stars_changed(new_stars: int) -> void:
	"""Update stars display."""
	if health_display and health_display.has_method("update_stars"):
		health_display.update_stars(new_stars)


func _on_game_state_changed(new_state: GameManager.GameState) -> void:
	"""Handle game state changes."""
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
	"""Show the game over screen."""
	# Could transition to a separate scene or show overlay
	print("GAME OVER")
	# ScreenManager.transition_to("res://Screens/game_over.tscn")


func _show_victory() -> void:
	"""Show the victory screen."""
	print("VICTORY!")
	var stats = GameManager.get_final_stats()
	print("Final Score: ", stats.score)
	print("Rating: ", stats.rating)
	# ScreenManager.transition_to("res://Screens/victory.tscn")


# ===== UTILITY =====

func get_current_enemy() -> Enemy:
	"""Returns the current enemy being fought."""
	return current_enemy


func restart_fight() -> void:
	"""Restart the current fight (for retry functionality)."""
	GameManager.start_game()
	spawn_next_enemy()
