extends Control

## ScoreDisplay - Shows score with "blop" animation and combo counter

@export var score_font: Font
@export var combo_font: Font
@export var blop_scale: float = 1.3
@export var blop_duration: float = 0.15

var score_label: Label
var combo_label: Label
var combo_container: Control

var current_displayed_score: int = 0
var target_score: int = 0
var score_tween: Tween


func _ready() -> void:
	_setup_ui()


func _setup_ui() -> void:
	# Position in top-right
	anchor_left = 1.0
	anchor_right = 1.0
	offset_left = -150
	offset_right = -16
	offset_top = 16
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_END
	add_child(vbox)
	
	# Score label
	score_label = Label.new()
	score_label.text = "0"
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if score_font:
		score_label.add_theme_font_override("font", score_font)
	score_label.add_theme_font_size_override("font_size", 24)
	score_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(score_label)
	
	# Combo container
	combo_container = Control.new()
	combo_container.custom_minimum_size = Vector2(100, 30)
	vbox.add_child(combo_container)
	
	# Combo label
	combo_label = Label.new()
	combo_label.text = ""
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if combo_font:
		combo_label.add_theme_font_override("font", combo_font)
	combo_label.add_theme_font_size_override("font_size", 16)
	combo_label.add_theme_color_override("font_color", Color.YELLOW)
	combo_container.add_child(combo_label)
	
	combo_container.visible = false


func update_score(new_score: int) -> void:
	"""Update the score display with blop animation."""
	target_score = new_score
	
	# Animate score counting up
	if score_tween and score_tween.is_valid():
		score_tween.kill()
	
	score_tween = create_tween()
	score_tween.tween_method(_set_score_text, current_displayed_score, target_score, 0.3)
	
	# Blop effect
	_play_blop()


func _set_score_text(value: int) -> void:
	current_displayed_score = value
	score_label.text = str(value)


func _play_blop() -> void:
	"""Scale up and back down quickly."""
	var blop_tween = create_tween()
	blop_tween.tween_property(score_label, "scale", Vector2(blop_scale, blop_scale), blop_duration * 0.5)
	blop_tween.tween_property(score_label, "scale", Vector2.ONE, blop_duration * 0.5)


func update_combo(combo: int) -> void:
	"""Update combo display."""
	if combo > 1:
		combo_container.visible = true
		combo_label.text = str(combo) + "x COMBO"
		
		# Color based on multiplier thresholds
		if combo >= 30:
			combo_label.add_theme_color_override("font_color", Color.GOLD)
		elif combo >= 20:
			combo_label.add_theme_color_override("font_color", Color.ORANGE)
		elif combo >= 10:
			combo_label.add_theme_color_override("font_color", Color.YELLOW)
		elif combo >= 5:
			combo_label.add_theme_color_override("font_color", Color.GREEN)
		else:
			combo_label.add_theme_color_override("font_color", Color.WHITE)
		
		# Pop effect
		_play_combo_pop()
	else:
		# Hide combo or show it breaking
		if combo_container.visible:
			_play_combo_break()


func _play_combo_pop() -> void:
	"""Quick pop animation on combo increase."""
	var pop_tween = create_tween()
	pop_tween.tween_property(combo_label, "scale", Vector2(1.2, 1.2), 0.05)
	pop_tween.tween_property(combo_label, "scale", Vector2.ONE, 0.1)


func _play_combo_break() -> void:
	"""Animation when combo breaks."""
	var break_tween = create_tween()
	combo_label.text = "COMBO BREAK!"
	combo_label.add_theme_color_override("font_color", Color.RED)
	
	break_tween.tween_property(combo_label, "modulate:a", 0.0, 0.5)
	break_tween.tween_callback(func(): combo_container.visible = false; combo_label.modulate.a = 1.0)
