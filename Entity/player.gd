extends Node2D
class_name Player

signal died

@export var base_damage: int = 1
@export var invulnerability_duration: float = 1.0

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
@onready var sfx_player: AudioStreamPlayer = AudioStreamPlayer.new()
const PUNCH_SOUND = preload("res://Assets/Audio/punch.wav")

var original_position: Vector2
var hit_tween: Tween
var flash_tween: Tween
var last_hit_direction: String
var is_invulnerable: bool = false
var invulnerability_timer: float = 0.0


func _ready() -> void:
	hitbox_shape.disabled = true
	blood_particles.emitting = false
	original_position = position
	sfx_player.bus = "SFX"
	add_child(sfx_player)
	
	_fix_collision_layers()
	
	# Connect hurtbox signals
	hurtbox_left.area_entered.connect(_on_hurtbox_hit.bind("left"))
	hurtbox_right.area_entered.connect(_on_hurtbox_hit.bind("right"))
	hurtbox_overhead.area_entered.connect(_on_hurtbox_hit.bind("overhead"))
	
	# Connect hitbox for scoring
	hitbox.area_entered.connect(_on_hitbox_hit)


func _fix_collision_layers() -> void:
	# HurtBoxLeft - Layer 1 (bit value 1)
	hurtbox_left.collision_layer = 1
	hurtbox_left.collision_mask = 32  # Detect EnemyAttack layer
	
	# HurtBoxRight - Layer 2 (bit value 2)
	hurtbox_right.collision_layer = 2
	hurtbox_right.collision_mask = 32
	
	# HurtBoxOverhead - Layer 3 (bit value 4)
	hurtbox_overhead.collision_layer = 4
	hurtbox_overhead.collision_mask = 32
	
	print("[PLAYER] Collision layers fixed: Left=layer1, Right=layer2, Overhead=layer4")


func _process(delta: float) -> void:
	if is_invulnerable:
		invulnerability_timer -= delta
		if invulnerability_timer <= 0:
			_end_invulnerability()


func _on_hurtbox_hit(area: Area2D, hurtbox_direction: String) -> void:
	if is_invulnerable:
		return
	
	if not GameManager.is_playing():
		return
	
	var enemy_mask = area.collision_mask
	var expected_layer = 0
	match hurtbox_direction:
		"left":
			expected_layer = 1
		"right":
			expected_layer = 2
		"overhead":
			expected_layer = 4

	if (enemy_mask & expected_layer) == 0:
		# This hurtbox wasn't the intended target - ignore
		print("[PLAYER] Ignoring hit on '%s' - enemy targeting mask %d, not layer %d" % [hurtbox_direction, enemy_mask, expected_layer])
		return
	
	# Get current state for debug
	var current_state_name = "unknown"
	if state_machine and state_machine.current_state:
		current_state_name = state_machine.current_state.name
	
	# STATE-BASED DODGE CHECK (primary method)
	var dodged_by_state = false
	match hurtbox_direction:
		"left":
			# Attack targeting left hurtbox -> dodge RIGHT to avoid
			if current_state_name == "DodgeRightState":
				dodged_by_state = true
		"right":
			# Attack targeting right hurtbox -> dodge LEFT to avoid
			if current_state_name == "DodgeLeftState":
				dodged_by_state = true
		"overhead":
			# Overhead attack -> DUCK to avoid
			if current_state_name == "DuckState":
				dodged_by_state = true
	
	# COLLISION SHAPE CHECK (backup method)
	var hurtbox_disabled: bool = false
	match hurtbox_direction:
		"left":
			hurtbox_disabled = hurtbox_left_shape.disabled
		"right":
			hurtbox_disabled = hurtbox_right_shape.disabled
		"overhead":
			hurtbox_disabled = hurtbox_overhead_shape.disabled
	
	print("[PLAYER] Hit on '%s' (enemy mask=%d) | State: %s | Dodged: %s | Disabled: %s" % [hurtbox_direction, enemy_mask, current_state_name, dodged_by_state, hurtbox_disabled])
	
	if dodged_by_state or hurtbox_disabled:
		print("[PLAYER] DODGED attack targeting: %s" % hurtbox_direction)
		GameManager.register_dodge_success(false)
		return
	
	var damage: int = 1
	if area.has_meta("damage"):
		damage = area.get_meta("damage")
	
	print("[PLAYER] TAKING DAMAGE: %d from: %s" % [damage, hurtbox_direction])
	take_damage(damage, hurtbox_direction)


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
	invulnerability_timer = invulnerability_duration
	
	# Kill any existing flash tween
	if flash_tween and flash_tween.is_valid():
		flash_tween.kill()
	
	# Create flashing effect
	flash_tween = create_tween()
	flash_tween.set_loops(int(invulnerability_duration / 0.2))
	flash_tween.tween_property(sprite, "modulate:a", 0.5, 0.1)
	flash_tween.tween_property(sprite, "modulate:a", 1.0, 0.1)


func _end_invulnerability() -> void:
	is_invulnerable = false
	invulnerability_timer = 0.0
	
	# Stop flashing
	if flash_tween and flash_tween.is_valid():
		flash_tween.kill()
	
	sprite.modulate.a = 1.0


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
	# Direct assignment for immediate effect - critical for dodge timing
	hurtbox_left_shape.disabled = not left
	hurtbox_right_shape.disabled = not right
	hurtbox_overhead_shape.disabled = not overhead
	
	# Debug output to verify dodge state
	var state = "L:%s R:%s O:%s" % [left, right, overhead]
	print("[PLAYER] Hurtboxes set: %s" % state)


func is_dodging() -> bool:
	if not state_machine or not state_machine.current_state:
		return false
	var state_name = state_machine.current_state.name.to_lower()
	return "dodge" in state_name or "duck" in state_name
