extends Node
## GameManager responsibilities:
## - Current difficulty and HP values
## - Current score
## - Game state (menu, playing, paused, game_over, victory)
## - Functions to modify score, take damage, reset game

enum Difficulty { EASY, MEDIUM, HARD }
enum GameState { MENU, INTRO, PLAYING, PAUSED, GAME_OVER, VICTORY }

signal hp_changed(current_hp: int, max_hp: int)
signal score_changed(score: int)
signal game_state_changed(new_state: GameState)
signal player_died()

var max_hp: int = 3
var current_hp: int = 3
var score: int = 0
var difficulty: Difficulty = Difficulty.MEDIUM
var game_state: GameState = GameState.MENU

const HP_VALUES := {
	Difficulty.EASY: 5,   
	Difficulty.MEDIUM: 3, 
	Difficulty.HARD: 1    
}

const RATING_THRESHOLDS := {
	"S": 10000,
	"A": 7500,
	"B": 5000,
	"C": 2500,
	"D": 0
}


func _ready() -> void:
	_set_difficulty_by_date()


func _set_difficulty_by_date() -> void:
	var date := Time.get_date_dict_from_system()
	var day: int = date["day"]
	var month: int = date["month"]
	
	if month == 12:
		if day < 12:
			set_difficulty(Difficulty.EASY)
		elif day <= 19:
			set_difficulty(Difficulty.MEDIUM)
		else:
			set_difficulty(Difficulty.HARD)
	else:
		set_difficulty(Difficulty.MEDIUM)


func start_game() -> void:
	"""Resets HP and score, sets state to PLAYING."""
	current_hp = max_hp
	score = 0
	set_game_state(GameState.PLAYING)
	hp_changed.emit(current_hp, max_hp)
	score_changed.emit(score)


func take_damage(amount: int = 1) -> void:
	"""Reduces HP by amount, checks for death."""
	if game_state != GameState.PLAYING:
		return
	
	current_hp = max(0, current_hp - amount)
	hp_changed.emit(current_hp, max_hp)
	
	if current_hp <= 0:
		_on_player_death()


func heal(amount: int = 1) -> void:
	"""Restores HP by amount, capped at max_hp."""
	if game_state != GameState.PLAYING:
		return
	
	current_hp = min(max_hp, current_hp + amount)
	hp_changed.emit(current_hp, max_hp)


func add_score(amount: int) -> void:
	"""Increases score by amount."""
	score += amount
	score_changed.emit(score)


func calculate_rating() -> String:
	"""Returns S/A/B/C/D rating based on current score."""
	if score >= RATING_THRESHOLDS["S"]:
		return "S"
	elif score >= RATING_THRESHOLDS["A"]:
		return "A"
	elif score >= RATING_THRESHOLDS["B"]:
		return "B"
	elif score >= RATING_THRESHOLDS["C"]:
		return "C"
	else:
		return "D"


func set_difficulty(level: Difficulty) -> void:
	"""Sets max_hp based on difficulty level."""
	difficulty = level
	max_hp = HP_VALUES[difficulty]
	
	# If not currently playing, also update current_hp
	if game_state != GameState.PLAYING:
		current_hp = max_hp


func set_game_state(new_state: GameState) -> void:
	"""Updates the game state and emits signal."""
	game_state = new_state
	game_state_changed.emit(new_state)


func pause_game() -> void:
	"""Pauses the game if currently playing."""
	if game_state == GameState.PLAYING:
		set_game_state(GameState.PAUSED)
		get_tree().paused = true


func resume_game() -> void:
	"""Resumes the game if currently paused."""
	if game_state == GameState.PAUSED:
		set_game_state(GameState.PLAYING)
		get_tree().paused = false


func toggle_pause() -> void:
	"""Toggles between PLAYING and PAUSED states."""
	if game_state == GameState.PLAYING:
		pause_game()
	elif game_state == GameState.PAUSED:
		resume_game()


func trigger_victory() -> void:
	"""Sets game state to VICTORY."""
	set_game_state(GameState.VICTORY)


func reset_to_menu() -> void:
	"""Resets everything and returns to menu."""
	get_tree().paused = false
	score = 0
	current_hp = max_hp
	set_game_state(GameState.MENU)


func _on_player_death() -> void:
	"""Called when HP reaches zero."""
	player_died.emit()
	set_game_state(GameState.GAME_OVER)


# Utility getters
func get_hp_percentage() -> float:
	"""Returns current HP as a percentage (0.0 to 1.0)."""
	if max_hp == 0:
		return 0.0
	return float(current_hp) / float(max_hp)


func is_playing() -> bool:
	"""Returns true if game is in PLAYING state."""
	return game_state == GameState.PLAYING


func get_difficulty_name() -> String:
	"""Returns the current difficulty as a string."""
	match difficulty:
		Difficulty.EASY:
			return "Easy"
		Difficulty.MEDIUM:
			return "Medium"
		Difficulty.HARD:
			return "Hard"
	return "Unknown"
