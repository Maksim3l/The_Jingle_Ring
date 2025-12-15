extends Node2D
class_name Player

signal died

@export var base_damage: int = 1
@export var invulnerability_duration: float = 1.0  # NEW: Time in seconds to be safe

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D

# Make sure these match your scene node names exactly
@onready var hurtbox_left: Area2D = $HurtBoxLeft
@onready var hurtbox_left_shape: CollisionShape2D = $HurtBoxLeft/CollisionShape2D
@onready var hurtbox_right: Area2D = $HurtBoxRight
@onready var hurtbox_right_shape: CollisionShape2D = $HurtBoxRight/CollisionShape2D
@onready var hurtbox_overhead: Area2D = $HurtBoxOverhead
@onready var hurtbox_overhead_shape: CollisionShape2D = $HurtBoxOverhead/CollisionShape2D

@onready var blood_particles: GPUParticles2D = $BloodParticles
@onready var state_machine: StateMachine = $StateMachine
@onready var sfx_player: AudioStreamPlayer = AudioStreamPlayer.new()
const PUNCH_SOUND = preload("res://Assets/Audio/punch.wav")

var original_position: Vector2
var hit_tween: Tween
var last_hit_direction: String
var is_invulnerable: bool = false


func _ready() -> void:
	hitbox_shape.disabled = true
	blood_particles.emitting = false
	original_position = position
	sfx_player.bus = "SFX"
	add_child(sfx_player)
	
	# Connect hurtbox signals
	hurtbox_left.area_entered.connect(_on_hurtbox_hit.bind("left"))
	hurtbox_right.area_entered.connect(_on_hurtbox_hit.bind("right"))
	hurtbox_overhead.area_entered.connect(_on_hurtbox_hit.bind("overhead"))
	
	# Connect hitbox for scoring
	hitbox.area_entered.connect(_on_hitbox_hit)


func _on_hurtbox_hit(area: Area2D, direction: String) -> void:
	if is_invulnerable:
		return
	
	if not GameManager.is_playing():
		return
	
	var damage: int = 1
	if area.has_meta("damage"):
		damage = area.get_meta("damage")
	
	take_damage(damage, direction)


func _on_hitbox_hit(_area: Area2D) -> void:
	if is_invulnerable:
		return
		
	if not GameManager.is_playing():
		return
	
	# Determine hit type based on current state
	var hit_type: String = "light_hit"
	if state_machine.current_state:
		var current_state_name: String = state_machine.current_state.name.to_lower()
		
		if "heavy" in current_state_name:
			hit_type = "heavy_hit"
	
	GameManager.register_hit(hit_type)


func take_damage(damage: int, direction: String = "center") -> void:
	if is_invulnerable:
		return
	
	last_hit_direction = direction
	GameManager.take_damage(damage)
	state_machine.call_deferred("change_state", "HitState")
	
	_start_invulnerability()

func _start_invulnerability() -> void:
	is_invulnerable = true
	
	if hit_tween and hit_tween.is_valid():
		hit_tween.kill()
		
	hit_tween = create_tween()
	hit_tween.set_parallel(true)
	
	var num_loops = int(invulnerability_duration / 0.2)
	
	var flash_sequence = create_tween().set_loops(num_loops)
	flash_sequence.tween_property(sprite, "modulate:a", 0.5, 0.1) # Fade out
	flash_sequence.tween_property(sprite, "modulate:a", 1.0, 0.1) # Fade in
	hit_tween.tween_interval(0)
	hit_tween.set_parallel(false)
	hit_tween.tween_interval(invulnerability_duration)

	hit_tween.tween_callback(func():
		is_invulnerable = false
		sprite.modulate.a = 1.0 
		flash_sequence.kill()
		)

# ===== HIT FEEDBACK METHODS =====

func play_attack_sound() -> void:
	sfx_player.stream = PUNCH_SOUND
	sfx_player.play()

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
	hurtbox_left_shape.set_deferred("disabled", not left)
	hurtbox_right_shape.set_deferred("disabled", not right)
	hurtbox_overhead_shape.set_deferred("disabled", not overhead)
