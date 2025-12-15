extends Enemy
class_name Wham


func _ready() -> void:
	# Stage 1: Very slow tutorial boss
	max_hp = 5
	attack_damage = 1
	telegraph_duration = 2  # Very long telegraph
	idle_duration_min = 2
	idle_duration_max = 2
	score_value = 1000
	max_phases = 2
	
	# No buffs
	buff_chance = 0.0
	available_buffs = []
	
	# Background music for this enemy
	background_music = "wham.wav"
	
	super._ready()


func _setup_attacks() -> void:
	# Register Wham's attacks with sounds
	# Format: register_attack(attack_key, direction, tell_anim, attack_anim, sound)
	
	# Cork attack - shoots overhead
	register_attack("cork", "left", "tell_cork", "attack_cork", "cork pop.wav")
	
	# Bottle attack - swings left/right (we'll make it hit left for now)
	register_attack("bottle", "overhead", "tell_bottle", "attack_bottle", "bottle toss.wav")
	
	# Phase 1: Mostly cork, some bottle
	available_attacks = ["cork", "cork", "bottle"]


func _on_phase_changed() -> void:
	match current_phase:
		2:
			# Stage 2: Faster, more HP
			max_hp = 50
			current_hp = max_hp
			
			telegraph_duration = 1
			idle_duration_min = 1
			idle_duration_max = 1
			
			# Phase 2: More aggressive mix
			available_attacks = ["cork", "bottle", "cork", "bottle"]
			
			# Update base stats
			base_telegraph_duration = telegraph_duration
			base_idle_duration_min = idle_duration_min
			base_idle_duration_max = idle_duration_max
			
			print("Wham enters Stage 2!")
