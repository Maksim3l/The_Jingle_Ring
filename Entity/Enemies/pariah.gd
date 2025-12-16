extends Enemy
class_name PariahScary


func _ready() -> void:
	max_hp = 100
	attack_damage = 1
	telegraph_duration = 0.8
	idle_duration_min = 0.8
	idle_duration_max = 1.5
	score_value = 10000
	max_phases = 1
	
	# Buff settings
	buff_chance = 0.15
	buff_duration = 1.2
	
	# Only heal buff
	available_buffs = ["heal"]
	
	# Background music for this enemy
	background_music = "pyryah scary.wav"
	
	super._ready()


func _setup_attacks() -> void:
	# Claw attacks
	register_attack("claw_left", "left", "tell_claw_left", "claw_left", "claw.wav")
	register_attack("claw_right", "right", "tell_claw_right", "claw_right", "claw.wav")
	
	# Kick attacks
	register_attack("kick_left", "left", "tell_kick_left", "kick_left", "kick.wav")
	register_attack("kick_right", "right", "tell_kick_right", "kicl_right", "kick.wav")  # Note: typo in animation name
	
	# Set available attacks (can weight by adding duplicates)
	# Claws more common than kicks
	available_attacks = [
		"claw_left", "claw_right",
		"claw_left", "claw_right",  # Claws more common
		"kick_left", "kick_right"
	]


func _on_phase_changed() -> void:
	base_telegraph_duration = telegraph_duration
	base_idle_duration_min = idle_duration_min
	base_idle_duration_max = idle_duration_max
	base_attack_damage = attack_damage
