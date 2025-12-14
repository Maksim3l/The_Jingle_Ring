extends Control

## HealthDisplay - Shows player hearts and stars

@export var heart_full_texture: Texture2D
@export var heart_empty_texture: Texture2D
@export var star_full_texture: Texture2D
@export var star_empty_texture: Texture2D

@export var heart_size: Vector2 = Vector2(24, 24)
@export var star_size: Vector2 = Vector2(20, 20)
@export var spacing: float = 4.0

var heart_container: HBoxContainer
var star_container: HBoxContainer
var hearts: Array[TextureRect] = []
var stars: Array[TextureRect] = []

const MAX_HEARTS: int = 5
const MAX_STARS: int = 3


func _ready() -> void:
	_setup_containers()
	_create_hearts()
	_create_stars()


func _setup_containers() -> void:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	add_child(vbox)
	
	heart_container = HBoxContainer.new()
	heart_container.add_theme_constant_override("separation", int(spacing))
	vbox.add_child(heart_container)
	
	star_container = HBoxContainer.new()
	star_container.add_theme_constant_override("separation", int(spacing))
	vbox.add_child(star_container)


func _create_hearts() -> void:
	hearts.clear()
	
	for i in range(MAX_HEARTS):
		var heart = TextureRect.new()
		heart.custom_minimum_size = heart_size
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.texture = heart_full_texture
		heart_container.add_child(heart)
		hearts.append(heart)


func _create_stars() -> void:
	stars.clear()
	
	for i in range(MAX_STARS):
		var star = TextureRect.new()
		star.custom_minimum_size = star_size
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star.texture = star_empty_texture
		star_container.add_child(star)
		stars.append(star)


func update_health(current: int, maximum: int) -> void:
	for i in range(hearts.size()):
		if i < maximum:
			hearts[i].visible = true
			if i < current:
				hearts[i].texture = heart_full_texture
				hearts[i].modulate = Color.WHITE
			else:
				hearts[i].texture = heart_empty_texture
				hearts[i].modulate = Color(1, 1, 1, 0.5)
		else:
			hearts[i].visible = false
	
	if current < maximum:
		_flash_hearts()


func update_stars(current: int) -> void:
	for i in range(stars.size()):
		if i < current:
			stars[i].texture = star_full_texture
			stars[i].modulate = Color.YELLOW
		else:
			stars[i].texture = star_empty_texture
			stars[i].modulate = Color(1, 1, 1, 0.3)


func _flash_hearts() -> void:
	var tween = create_tween()
	for heart in hearts:
		tween.parallel().tween_property(heart, "modulate", Color.RED, 0.1)
	tween.tween_interval(0.1)
	for heart in hearts:
		tween.parallel().tween_property(heart, "modulate", Color.WHITE, 0.1)
