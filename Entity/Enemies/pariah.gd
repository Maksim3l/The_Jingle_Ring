extends Enemy
class_name PariahScary


func _ready() -> void:
	max_hp = 10
	attack_damage = 1
	telegraph_duration = 0.4
	idle_duration_min = 0.8
	idle_duration_max = 1.5
	score_value = 10000
	max_phases = 1
	
	# Buff settings
	buff_chance = 0.15
	buff_duration = 1.2
	
	# Only left and right attacks
	available_attacks = ["left", "right"]
	
	# Only heal buff
	available_buffs = ["heal"]
	
	super._ready()


func _on_phase_changed() -> void:
	base_telegraph_duration = telegraph_duration
	base_idle_duration_min = idle_duration_min
	base_idle_duration_max = idle_duration_max
	base_attack_damage = attack_damage
