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
var current_attack_type: String = ""
var current_buff_type: String = ""

# Base stats (for resetting buffs)
var base_telegraph_duration: float
var base_idle_duration_min: float
var base_idle_duration_max: float
var base_attack_damage: int

# Attack types this enemy can use
var available_attacks: Array[String] = ["left", "right", "overhead"]

# Buff types this enemy can use
var available_buffs: Array[String] = []

# Active buffs tracking
var active_buffs: Dictionary = {}

# Node references
@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var state_machine: StateMachine = $StateMachine
@onready var health_bar: ProgressBar = $HealthBar

# Hitboxes (enemy attacks player)
@onready var hitbox_left: Area2D = $HitboxLeft
@onready var hitbox_left_shape: CollisionShape2D = $HitboxLeft/CollisionShape2D
@onready var hitbox_right: Area2D = $HitboxRight
@onready var hitbox_right_shape: CollisionShape2D = $HitboxRight/CollisionShape2D
@onready var hitbox_overhead: Area2D = $HitboxOverhead
@onready var hitbox_overhead_shape: CollisionShape2D = $HitboxOverhead/CollisionShape2D

# Hurtbox (where player hits enemy)
@onready var hurtbox: Area2D = $HurtBox
@onready var hurtbox_shape: CollisionShape2D = $HurtBox/CollisionShape2D

# Tell indicators
@onready var tell_left: Sprite2D = $TellLeft
@onready var tell_right: Sprite2D = $TellRight
@onready var tell_overhead: Sprite2D = $TellOverhead

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
	
	# Disable all hitboxes at start
	disable_all_hitboxes()
	
	# Hide tell indicators
	_hide_all_tells()
	
	# Update health bar
	_update_health_bar()
	
	# Connect hurtbox signal
	if hurtbox:
		hurtbox.area_entered.connect(_on_hurtbox_hit)
	
	# Connect hitbox signals
	if hitbox_left:
		hitbox_left.area_entered.connect(_on_attack_landed)
	if hitbox_right:
		hitbox_right.area_entered.connect(_on_attack_landed)
	if hitbox_overhead:
		hitbox_overhead.area_entered.connect(_on_attack_landed)
	
	_update_hitbox_damage()
	
	# Initialize state machine
	await get_tree().process_frame
	if state_machine and state_machine.states.has("idlestate"):
		state_machine.change_state("IdleState")


func _update_hitbox_damage() -> void:
	if hitbox_left:
		hitbox_left.set_meta("damage", attack_damage)
	if hitbox_right:
		hitbox_right.set_meta("damage", attack_damage)
	if hitbox_overhead:
		hitbox_overhead.set_meta("damage", attack_damage)


func _update_health_bar() -> void:
	if health_bar:
		health_bar.value = get_hp_percentage() * 100.0


func _hide_all_tells() -> void:
	if tell_left:
		tell_left.visible = false
	if tell_right:
		tell_right.visible = false
	if tell_overhead:
		tell_overhead.visible = false


# ===== DAMAGE & HEALTH =====

func _on_hurtbox_hit(area: Area2D) -> void:
	if not GameManager.is_playing():
		return
	
	var damage: int = 1
	if area.has_meta("damage"):
		damage = area.get_meta("damage")
	
	take_damage(damage)


func take_damage(amount: int) -> void:
	# Apply damage reduction from buffs
	var actual_damage: int = int(amount * get_damage_reduction())
	actual_damage = max(1, actual_damage)
	
	current_hp -= actual_damage
	current_hp = max(0, current_hp)
	
	_update_health_bar()
	
	# Interrupt buff if currently buffing
	if is_buffing():
		interrupt_buff()
	
	if current_hp <= 0:
		if current_phase < max_phases:
			trigger_phase_transition()
		else:
			state_machine.change_state("DieState")
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
	current_attack_type = available_attacks[randi() % available_attacks.size()]
	return current_attack_type


func choose_buff() -> String:
	current_buff_type = available_buffs[randi() % available_buffs.size()]
	return current_buff_type


# ===== ATTACK SYSTEM =====

func enable_hitbox(attack_type: String) -> void:
	disable_all_hitboxes()
	
	match attack_type:
		"left":
			if hitbox_left_shape:
				hitbox_left_shape.disabled = false
		"right":
			if hitbox_right_shape:
				hitbox_right_shape.disabled = false
		"overhead":
			if hitbox_overhead_shape:
				hitbox_overhead_shape.disabled = false
	
	current_attack_type = attack_type
	attack_started.emit(attack_type)


func disable_all_hitboxes() -> void:
	if hitbox_left_shape:
		hitbox_left_shape.disabled = true
	if hitbox_right_shape:
		hitbox_right_shape.disabled = true
	if hitbox_overhead_shape:
		hitbox_overhead_shape.disabled = true


func _on_attack_landed(_area: Area2D) -> void:
	attack_landed.emit()


# ===== TELL INDICATORS =====

func show_tell(direction: String) -> void:
	_hide_all_tells()
	
	match direction:
		"left":
			if tell_left:
				tell_left.visible = true
		"right":
			if tell_right:
				tell_right.visible = true
		"overhead":
			if tell_overhead:
				tell_overhead.visible = true


func hide_tells() -> void:
	_hide_all_tells()


# ===== BUFF SYSTEM =====

func is_buffing() -> bool:
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


func start_hit_particles() -> void:
	# Override if you add hit particles
	pass


func stop_hit_particles() -> void:
	pass


func play_hit_feedback() -> void:
	flash_white()
	wobble()
	start_hit_particles()


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
