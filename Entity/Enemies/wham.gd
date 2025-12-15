extends Enemy
class_name Wham


func _ready() -> void:
	max_hp = 5
	attack_damage = 1
	telegraph_duration = 1.5
	idle_duration_min = 2
	idle_duration_max = 2
	score_value = 1000
	max_phases = 2
	
	# No buffs
	buff_chance = 0.0
	available_buffs = []
	
	background_music = "wham.wav"
	
	super._ready()


func _setup_attacks() -> void:
	register_attack("cork", "left", "tell_cork", "attack_cork", "cork pop.wav")
	register_attack("bottle", "overhead", "tell_bottle", "attack_bottle", "bottle toss.wav")
	
	available_attacks = ["cork", "cork", "bottle"]


func _on_phase_changed() -> void:
	match current_phase:
		2:
			max_hp = 50
			current_hp = max_hp
			
			telegraph_duration = 1
			idle_duration_min = 1
			idle_duration_max = 1
			
			available_attacks = ["cork", "bottle", "cork", "bottle"]
			base_telegraph_duration = telegraph_duration
			base_idle_duration_min = idle_duration_min
			base_idle_duration_max = idle_duration_max
			
			print("Wham enters Stage 2!")
