extends Node

## GameManager responsibilities:
## - Current difficulty and HP values
## - Current score, combo, stars
## - Game state (menu, playing, paused, game_over, victory)
## - Functions to modify score, take damage, reset game

enum Difficulty { EASY, MEDIUM, HARD }
enum GameState { MENU, INTRO, DIFFICULTY_SELECT, PLAYING, PAUSED, GAME_OVER, VICTORY }

signal hp_changed(current_hp: int, max_hp: int)
signal score_changed(score: int)
signal combo_changed(combo: int)
signal stars_changed(stars: int)
signal game_state_changed(new_state: GameState)
signal player_died()
signal difficulty_selected(difficulty: Difficulty)

var max_hp: int = 3
var current_hp: int = 3
var score: int = 0
var combo: int = 0
var max_combo: int = 0
var stars: int = 0
var difficulty: Difficulty = Difficulty.MEDIUM
var game_state: GameState = GameState.MENU

const MAX_STARS: int = 3

const HP_VALUES := {
	Difficulty.EASY: 5,
	Difficulty.MEDIUM: 3,
	Difficulty.HARD: 1
}

const SCORE_VALUES := {
	"light_hit": 100,
	"heavy_hit": 250,
	"star_punch": 500,
	"dodge_success": 50,
	"duck_success": 50,
	"knockout": 1000,
	"perfect_dodge": 150,
}

const COMBO_MULTIPLIERS := {
	0: 1.0,
	5: 1.5,
	10: 2.0,
	20: 2.5,
	30: 3.0,
}

# Rating thresholds - D to SSS
const RATING_THRESHOLDS := {
	"SSS": 15000,
	"SS": 12500,
	"S": 10000,
	"A": 7500,
	"B": 5000,
	"C": 2500,
	"D": 0
}

# Bonus multipliers for difficulty
const DIFFICULTY_SCORE_MULTIPLIER := {
	Difficulty.EASY: 0.5,
	Difficulty.MEDIUM: 1.0,
	Difficulty.HARD: 2.0
}


func _ready() -> void:
	pass


# ===== GAME FLOW =====

func start_game() -> void:
	"""Resets HP and score, sets state to PLAYING."""
	current_hp = max_hp
	score = 0
	combo = 0
	max_combo = 0
	stars = 0
	set_game_state(GameState.PLAYING)
	hp_changed.emit(current_hp, max_hp)
	score_changed.emit(score)
	combo_changed.emit(combo)
	stars_changed.emit(stars)


func show_difficulty_select() -> void:
	"""Shows the difficulty selection screen."""
	set_game_state(GameState.DIFFICULTY_SELECT)


func select_difficulty(level: Difficulty) -> void:
	"""Called when player selects difficulty."""
	set_difficulty(level)
	difficulty_selected.emit(level)


func set_difficulty(level: Difficulty) -> void:
	"""Sets max_hp based on difficulty level."""
	difficulty = level
	max_hp = HP_VALUES[difficulty]
	
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
	combo = 0
	max_combo = 0
	stars = 0
	current_hp = max_hp
	set_game_state(GameState.MENU)


# ===== DAMAGE & HEALTH =====

func take_damage(amount: int = 1) -> void:
	"""Reduces HP by amount, checks for death."""
	if game_state != GameState.PLAYING:
		return
	
	current_hp = max(0, current_hp - amount)
	hp_changed.emit(current_hp, max_hp)
	
	# Break combo when hit
	break_combo()
	
	if current_hp <= 0:
		_on_player_death()


func heal(amount: int = 1) -> void:
	"""Restores HP by amount, capped at max_hp."""
	if game_state != GameState.PLAYING:
		return
	
	current_hp = min(max_hp, current_hp + amount)
	hp_changed.emit(current_hp, max_hp)


func _on_player_death() -> void:
	"""Called when HP reaches zero."""
	player_died.emit()
	set_game_state(GameState.GAME_OVER)


# ===== SCORE & COMBO =====

func get_combo_multiplier() -> float:
	"""Returns score multiplier based on current combo."""
	var multiplier: float = 1.0
	for threshold in COMBO_MULTIPLIERS.keys():
		if combo >= threshold:
			multiplier = COMBO_MULTIPLIERS[threshold]
	return multiplier


func add_score(amount: int) -> void:
	"""Increases score by amount (applies difficulty multiplier)."""
	var final_amount: int = int(amount * DIFFICULTY_SCORE_MULTIPLIER[difficulty])
	score += final_amount
	score_changed.emit(score)


func register_hit(hit_type: String = "light_hit") -> void:
	"""Called when player successfully hits enemy."""
	if game_state != GameState.PLAYING:
		return
	
	combo += 1
	max_combo = max(max_combo, combo)
	combo_changed.emit(combo)
	
	var base_score: int = SCORE_VALUES.get(hit_type, 100)
	var final_score: int = int(base_score * get_combo_multiplier())
	add_score(final_score)


func register_dodge_success(is_perfect: bool = false) -> void:
	"""Called when player successfully dodges an attack."""
	if game_state != GameState.PLAYING:
		return
	
	if is_perfect:
		add_score(SCORE_VALUES["perfect_dodge"])
		add_star()
	else:
		add_score(SCORE_VALUES["dodge_success"])


func register_duck_success() -> void:
	"""Called when player successfully ducks an attack."""
	if game_state != GameState.PLAYING:
		return
	
	add_score(SCORE_VALUES["duck_success"])


func break_combo() -> void:
	"""Called when player gets hit - resets combo."""
	combo = 0
	combo_changed.emit(combo)


# ===== STARS =====

func add_star() -> void:
	"""Adds a star (max 3) for star punch."""
	if stars < MAX_STARS:
		stars += 1
		stars_changed.emit(stars)


func use_star() -> bool:
	"""Uses a star for star punch. Returns true if successful."""
	if stars > 0:
		stars -= 1
		stars_changed.emit(stars)
		return true
	return false


func use_all_stars() -> int:
	"""Uses all stars for super star punch. Returns number used."""
	var used: int = stars
	stars = 0
	stars_changed.emit(stars)
	return used


func has_stars() -> bool:
	"""Returns true if player has at least one star."""
	return stars > 0


# ===== RATING =====

func calculate_rating() -> String:
	"""Returns SSS/SS/S/A/B/C/D rating based on current score."""
	for rating in ["SSS", "SS", "S", "A", "B", "C", "D"]:
		if score >= RATING_THRESHOLDS[rating]:
			return rating
	return "D"


func get_rating_color(rating: String) -> Color:
	"""Returns color for rating display."""
	match rating:
		"SSS":
			return Color.GOLD
		"SS":
			return Color.YELLOW
		"S":
			return Color.ORANGE
		"A":
			return Color.GREEN
		"B":
			return Color.CYAN
		"C":
			return Color.WHITE
		"D":
			return Color.GRAY
	return Color.WHITE


# ===== UTILITY GETTERS =====

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


func get_final_stats() -> Dictionary:
	"""Returns stats dictionary for end screen."""
	return {
		"score": score,
		"rating": calculate_rating(),
		"max_combo": max_combo,
		"difficulty": get_difficulty_name(),
		"hp_remaining": current_hp,
		"max_hp": max_hp
	}
