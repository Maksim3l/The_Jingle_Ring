extends Node2D
class_name Player

signal died

@export var base_damage: int = 10

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D

@onready var hurtbox_left: Area2D = $HurtBoxLeft
@onready var hurtbox_left_shape: CollisionShape2D = $HurtBoxLeft/CollisionShape2D
@onready var hurtbox_right: Area2D = $HurtBoxRight
@onready var hurtbox_right_shape: CollisionShape2D = $HurtBoxRight/CollisionShape2D
@onready var hurtbox_overhead: Area2D = $HurtBoxOverhead
@onready var hurtbox_overhead_shape: CollisionShape2D = $HurtBoxOverhead/CollisionShape2D

@onready var blood_particles: GPUParticles2D = $BloodParticles
@onready var state_machine: StateMachine = $StateMachine

var original_position: Vector2
var hit_tween: Tween

func _ready() -> void:
	hitbox_shape.disabled = true
	blood_particles.emitting = false
	original_position = position
	
	# Connect hurtbox signals
	hurtbox_left.area_entered.connect(_on_hurtbox_hit.bind("left"))
	hurtbox_right.area_entered.connect(_on_hurtbox_hit.bind("right"))
	hurtbox_overhead.area_entered.connect(_on_hurtbox_hit.bind("overhead"))
	
	# Connect hitbox for scoring
	hitbox.area_entered.connect(_on_hitbox_hit)


func _on_hurtbox_hit(area: Area2D, direction: String) -> void:
	# Only take damage if game is playing
	if not GameManager.is_playing():
		return
	
	var damage: int = 1
	if area.has_meta("damage"):
		damage = area.get_meta("damage")
	
	take_damage(damage, direction)


func _on_hitbox_hit(area: Area2D) -> void:
	# Check if we hit an enemy hurtbox
	if not GameManager.is_playing():
		return
	
	# Determine hit type based on current state
	var hit_type: String = "light_hit"
	var current_state_name: String = state_machine.current_state.name.to_lower()
	
	if "heavy" in current_state_name:
		hit_type = "heavy_hit"
	elif "star" in current_state_name:
		hit_type = "star_punch"
	
	GameManager.register_hit(hit_type)


func take_damage(damage: int, _direction: String = "center") -> void:
	# Tell GameManager to reduce HP (also breaks combo)
	GameManager.take_damage(damage)
	
	# Force transition to hit state
	state_machine.change_state("HitState")


# ===== HIT FEEDBACK METHODS =====

func flash_red() -> void:
	if hit_tween and hit_tween.is_valid():
		hit_tween.kill()
	
	hit_tween = create_tween()
	sprite.modulate = Color(1, 0.3, 0.3, 1)
	hit_tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)


func wobble() -> void:
	var wobble_tween = create_tween()
	wobble_tween.tween_property(self, "position:x", original_position.x + 5, 0.05)
	wobble_tween.tween_property(self, "position:x", original_position.x - 5, 0.05)
	wobble_tween.tween_property(self, "position:x", original_position.x, 0.05)


func start_blood() -> void:
	blood_particles.emitting = true


func stop_blood() -> void:
	blood_particles.emitting = false


func play_all_hit_feedback() -> void:
	flash_red()
	wobble()
	start_blood()


func set_hurtboxes(left: bool, right: bool, overhead: bool) -> void:
	hurtbox_left_shape.disabled = not left
	hurtbox_right_shape.disabled = not right
	hurtbox_overhead_shape.disabled = not overhead


# ===== STAR PUNCH =====

func can_star_punch() -> bool:
	return GameManager.has_stars()


func do_star_punch() -> void:
	if GameManager.use_star():
		state_machine.change_state("StarPunchState")
