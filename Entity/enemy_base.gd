extends Node2D
class_name Enemy

signal died
signal phase_changed(new_phase: int)
signal attack_started(attack_type: String)
signal attack_landed
signal buff_started(buff_type: String)
signal buff_completed(buff_type: String)
signal buff_interrupted(buff_type: String)

# ===== STATS (override in child classes) =====
@export var max_hp: int = 3
@export var attack_damage: int = 1
@export var telegraph_duration: float = 0.5
@export var idle_duration_min: float = 1.0
@export var idle_duration_max: float = 2.5
@export var score_value: int = 100

# Phase tracking
@export var max_phases: int = 1

# Buff settings
@export var buff_chance: float = 0.2
@export var buff_duration: float = 1.0

var current_hp: int
var current_phase: int = 1
var current_attack_type: String = ""  # This is now the attack KEY (e.g., "claw_left")
var current_attack_direction: String = ""  # This is the direction (e.g., "left")
var current_buff_type: String = ""

# Base stats (for resetting buffs)
var base_telegraph_duration: float
var base_idle_duration_min: float
var base_idle_duration_max: float
var base_attack_damage: int

# ===== NEW ATTACK REGISTRY SYSTEM =====
# Dictionary of attack_key -> { "direction": String, "tell_anim": String, "attack_anim": String }
# Example: "claw_left" -> { "direction": "left", "tell_anim": "tell_claw_left", "attack_anim": "claw_left" }
var attack_registry: Dictionary = {}

# Array of attack keys that can be chosen (can have duplicates for weighting)
var available_attacks: Array[String] = []

# Buff types this enemy can use
var available_buffs: Array[String] = []

# Active buffs tracking
var active_buffs: Dictionary = {}

var hyper_armor: bool = true

# Node references
@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var state_machine: StateMachine = $StateMachine
@onready var health_bar: ProgressBar = $HealthBar

# Single hitbox - collision mask changes based on attack type
@onready var hitbox: Area2D = $HitBox
@onready var hitbox_shape: CollisionShape2D = $HitBox/CollisionShape2D

# Hurtbox (where player hits enemy)
@onready var hurtbox: Area2D = $HurtBox
@onready var hurtbox_shape: CollisionShape2D = $HurtBox/CollisionShape2D

var original_position: Vector2
var hit_tween: Tween
var buff_tween: Tween


func _ready() -> void:
	current_hp = max_hp
	original_position = position
	
	# Store base stats for buff reset
	base_telegraph_duration = telegraph_duration
	base_idle_duration_min = idle_duration_min
	base_idle_duration_max = idle_duration_max
	base_attack_damage = attack_damage
	
	# Setup attack registry (override in child classes)
	_setup_attacks()
	
	# Disable hitbox at start
	disable_hitbox()
	
	# Update health bar
	_update_health_bar()
	
	# Connect hurtbox signal
	if hurtbox:
		hurtbox.area_entered.connect(_on_hurtbox_hit)
	
	# Connect hitbox signal
	if hitbox:
		hitbox.area_entered.connect(_on_attack_landed)
	
	_update_hitbox_damage()


# ===== ATTACK REGISTRY SETUP =====
# Override this in child classes to define attacks
func _setup_attacks() -> void:
	# Default simple attacks (for backwards compatibility)
	# Child classes should override this completely
	register_attack("left", "left", "telegraph_left", "attack_left")
	register_attack("right", "right", "telegraph_right", "attack_right")
	register_attack("overhead", "overhead", "telegraph_overhead", "attack_overhead")
	available_attacks = ["left", "right"]


# Helper to register an attack
# attack_key: unique identifier for this attack (e.g., "claw_left", "kick_right")
# direction: which player hurtbox it targets ("left", "right", "overhead")
# tell_anim: animation name for telegraph (e.g., "tell_claw_left")
# attack_anim: animation name for attack (e.g., "claw_left")
func register_attack(attack_key: String, direction: String, tell_anim: String, attack_anim: String) -> void:
	attack_registry[attack_key] = {
		"direction": direction,
		"tell_anim": tell_anim,
		"attack_anim": attack_anim
	}


# Get attack data from registry
func get_attack_data(attack_key: String) -> Dictionary:
	if attack_registry.has(attack_key):
		return attack_registry[attack_key]
	# Fallback for simple direction-based attacks
	return {
		"direction": attack_key,
		"tell_anim": "telegraph_" + attack_key,
		"attack_anim": "attack_" + attack_key
	}


func _update_hitbox_damage() -> void:
	if hitbox:
		hitbox.set_meta("damage", attack_damage)


func _update_health_bar() -> void:
	if health_bar:
		health_bar.value = get_hp_percentage() * 100.0


# ===== TELL SYSTEM =====

func show_tell(attack_key: String) -> void:
	var attack_data = get_attack_data(attack_key)
	var anim_name = attack_data["tell_anim"]
	
	if anim_player.has_animation(anim_name):
		anim_player.play(anim_name)
	elif anim_player.has_animation("telegraph"):
		anim_player.play("telegraph")


func hide_tells() -> void:
	# Nothing to hide - tells are animations
	pass


# ===== DAMAGE & HEALTH =====

func _on_hurtbox_hit(area: Area2D) -> void:
	if not GameManager.is_playing():
		return
	
	var damage: int = 1
	if area.has_meta("damage"):
		damage = area.get_meta("damage")
	
	take_damage(damage)


func take_damage(amount: int) -> void:
	if current_hp <= 0:
		return
	
	var actual_damage: int = int(amount * get_damage_reduction())
	actual_damage = max(1, actual_damage)
	
	current_hp -= actual_damage
	current_hp = max(0, current_hp)
	
	_update_health_bar()
	
	if is_buffing():
		interrupt_buff()
	
	if current_hp <= 0:
		if current_phase < max_phases:
			trigger_phase_transition()
		else:
			died.emit()
			state_machine.change_state("DieState")
	else:
		# Hyper armor: just flash, don't change state
		if hyper_armor:
			flash_white()
		else:
			state_machine.change_state("HitState")

func heal(amount: int) -> void:
	current_hp = min(max_hp, current_hp + amount)
	_update_health_bar()


func trigger_phase_transition() -> void:
	current_phase += 1
	current_hp = max_hp
	
	# Reset buffs on phase change
	reset_all_buffs()
	
	_update_health_bar()
	
	phase_changed.emit(current_phase)
	_on_phase_changed()
	
	# Return to idle after phase transition
	state_machine.change_state("IdleState")


func _on_phase_changed() -> void:
	# Override in child classes
	pass


# ===== ACTION SELECTION =====

func choose_action() -> String:
	if available_buffs.size() > 0 and randf() < buff_chance:
		return "buff"
	return "attack"


func choose_attack() -> String:
	# Choose from available attack keys
	current_attack_type = available_attacks[randi() % available_attacks.size()]
	
	# Get the direction from the attack data
	var attack_data = get_attack_data(current_attack_type)
	current_attack_direction = attack_data["direction"]
	
	return current_attack_type


func choose_buff() -> String:
	current_buff_type = available_buffs[randi() % available_buffs.size()]
	return current_buff_type


# ===== ATTACK SYSTEM =====
# Single hitbox - we change the collision MASK to target different player hurtboxes
# Layer 1 = PlayerHurtboxLeft
# Layer 2 = PlayerHurtboxRight
# Layer 3 = PlayerHurtboxOverhead

func enable_hitbox(attack_key: String) -> void:
	if not hitbox or not hitbox_shape:
		return
	
	# Get the direction from attack data
	var attack_data = get_attack_data(attack_key)
	var direction = attack_data["direction"]
	
	# Set collision mask based on attack direction
	match direction:
		"left":
			hitbox.collision_mask = 1  # Layer 1: PlayerHurtboxLeft
		"right":
			hitbox.collision_mask = 2  # Layer 2: PlayerHurtboxRight
		"overhead":
			hitbox.collision_mask = 4  # Layer 3: PlayerHurtboxOverhead
	
	# Enable the hitbox
	hitbox_shape.disabled = false
	
	current_attack_type = attack_key
	current_attack_direction = direction
	attack_started.emit(attack_key)


func disable_hitbox() -> void:
	if hitbox_shape:
		hitbox_shape.disabled = true


func disable_all_hitboxes() -> void:
	disable_hitbox()


func _on_attack_landed(_area: Area2D) -> void:
	attack_landed.emit()


# ===== ANIMATION HELPERS =====

func play_attack_animation(attack_key: String) -> void:
	var attack_data = get_attack_data(attack_key)
	var anim_name = attack_data["attack_anim"]
	
	if anim_player.has_animation(anim_name):
		anim_player.play(anim_name)
	elif anim_player.has_animation("attack"):
		anim_player.play("attack")


func play_telegraph_animation(attack_key: String) -> void:
	var attack_data = get_attack_data(attack_key)
	var anim_name = attack_data["tell_anim"]
	
	if anim_player.has_animation(anim_name):
		anim_player.play(anim_name)
	elif anim_player.has_animation("telegraph"):
		anim_player.play("telegraph")


# ===== BUFF SYSTEM =====

func is_buffing() -> bool:
	if not state_machine or not state_machine.current_state:
		return false
	return current_buff_type != "" and state_machine.current_state.name == "BuffState"


func start_buff(buff_type: String) -> void:
	current_buff_type = buff_type
	buff_started.emit(buff_type)
	_start_buff_glow(buff_type)


func complete_buff() -> void:
	var buff_type = current_buff_type
	
	match buff_type:
		"heal":
			_apply_heal_buff()
		"speed_up":
			_apply_speed_buff()
		"power_up":
			_apply_power_buff()
		"shield":
			_apply_shield_buff()
	
	buff_completed.emit(buff_type)
	_end_buff_visuals()
	current_buff_type = ""


func interrupt_buff() -> void:
	var buff_type = current_buff_type
	
	buff_interrupted.emit(buff_type)
	_end_buff_visuals()
	current_buff_type = ""
	
	# Bonus score for interrupting
	GameManager.add_score(50)


func _start_buff_glow(buff_type: String) -> void:
	if buff_tween and buff_tween.is_valid():
		buff_tween.kill()
	
	var glow_color: Color
	match buff_type:
		"heal":
			glow_color = Color.GREEN
		"speed_up":
			glow_color = Color.YELLOW
		"power_up":
			glow_color = Color.RED
		"shield":
			glow_color = Color.CYAN
		_:
			glow_color = Color.PURPLE
	
	buff_tween = create_tween()
	buff_tween.set_loops()
	buff_tween.tween_property(sprite, "modulate", glow_color, 0.2)
	buff_tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)


func _end_buff_visuals() -> void:
	if buff_tween and buff_tween.is_valid():
		buff_tween.kill()
	
	sprite.modulate = Color.WHITE


# ===== BUFF EFFECTS =====

func _apply_heal_buff() -> void:
	var heal_amount: int = max(1, max_hp / 3)
	heal(heal_amount)


func _apply_speed_buff() -> void:
	active_buffs["speed_up"] = {
		"duration": 10.0,
		"timer": 0.0
	}
	
	telegraph_duration = base_telegraph_duration * 0.5
	idle_duration_min = base_idle_duration_min * 0.5
	idle_duration_max = base_idle_duration_max * 0.5


func _apply_power_buff() -> void:
	active_buffs["power_up"] = {
		"duration": 10.0,
		"timer": 0.0
	}
	
	attack_damage = base_attack_damage * 2
	_update_hitbox_damage()


func _apply_shield_buff() -> void:
	active_buffs["shield"] = {
		"duration": 8.0,
		"timer": 0.0
	}


func _process(delta: float) -> void:
	_update_buff_timers(delta)


func _update_buff_timers(delta: float) -> void:
	var expired_buffs: Array[String] = []
	
	for buff_name in active_buffs.keys():
		active_buffs[buff_name]["timer"] += delta
		
		if active_buffs[buff_name]["timer"] >= active_buffs[buff_name]["duration"]:
			expired_buffs.append(buff_name)
	
	for buff_name in expired_buffs:
		_remove_buff(buff_name)


func _remove_buff(buff_name: String) -> void:
	match buff_name:
		"speed_up":
			telegraph_duration = base_telegraph_duration
			idle_duration_min = base_idle_duration_min
			idle_duration_max = base_idle_duration_max
		"power_up":
			attack_damage = base_attack_damage
			_update_hitbox_damage()
		"shield":
			pass
	
	active_buffs.erase(buff_name)


func has_buff(buff_name: String) -> bool:
	return active_buffs.has(buff_name)


func reset_all_buffs() -> void:
	active_buffs.clear()
	
	telegraph_duration = base_telegraph_duration
	idle_duration_min = base_idle_duration_min
	idle_duration_max = base_idle_duration_max
	attack_damage = base_attack_damage
	_update_hitbox_damage()


# ===== HIT FEEDBACK =====

func flash_white() -> void:
	if hit_tween and hit_tween.is_valid():
		hit_tween.kill()
	
	hit_tween = create_tween()
	sprite.modulate = Color(2, 2, 2, 1)
	hit_tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)


func wobble() -> void:
	var wobble_tween = create_tween()
	wobble_tween.tween_property(self, "position:x", original_position.x - 5, 0.05)
	wobble_tween.tween_property(self, "position:x", original_position.x + 5, 0.05)
	wobble_tween.tween_property(self, "position:x", original_position.x, 0.05)


func play_hit_feedback() -> void:
	flash_white()
	wobble()


# ===== UTILITY =====

func get_random_idle_duration() -> float:
	return randf_range(idle_duration_min, idle_duration_max)


func is_dead() -> bool:
	return current_hp <= 0


func get_hp_percentage() -> float:
	if max_hp == 0:
		return 0.0
	return float(current_hp) / float(max_hp)


func get_damage_reduction() -> float:
	if has_buff("shield"):
		return 0.5
	return 1.0
