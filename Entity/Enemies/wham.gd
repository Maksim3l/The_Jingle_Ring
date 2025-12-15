extends Enemy
class_name Wham


func _ready() -> void:
	# Stage 1: Very slow tutorial boss
	max_hp = 5
	attack_damage = 1
	telegraph_duration = 1.0  # Very long telegraph
	idle_duration_min = 1.6
	idle_duration_max = 2.2
	score_value = 1000
	max_phases = 2
	
	# No buffs
	buff_chance = 0.0
	available_buffs = []
	
	# Mostly left/right, rare overhead
	available_attacks = ["left", "right", "left", "right", "overhead"]  # Weighted: overhead is rare
	
	super._ready()


func _on_phase_changed() -> void:
	match current_phase:
		2:
			# Stage 2: Faster, more HP, more overhead
			max_hp = 50
			current_hp = max_hp
			
			telegraph_duration = 0.6
			idle_duration_min = 0.8
			idle_duration_max = 1.2
			
			# More overhead attacks now
			available_attacks = ["left", "right", "overhead", "left", "right", "overhead"]
			
			# Update base stats
			base_telegraph_duration = telegraph_duration
			base_idle_duration_min = idle_duration_min
			base_idle_duration_max = idle_duration_max
			
			print("Wham enters Stage 2!")
