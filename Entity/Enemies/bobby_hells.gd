extends Enemy
class_name BobbyHells

# Track which animation variant to use
var attack_variants: Dictionary = {
	"left": ["swipe_left", "kick_left"],
	"right": ["swipe_right", "kick_right"],
	"overhead": ["overhead"]
}

var current_attack_animation: String = ""


func _ready() -> void:
	max_hp = 12
	attack_damage = 1
	telegraph_duration = 0.5
	idle_duration_min = 1.0
	idle_duration_max = 2.0
	score_value = 5000
	max_phases = 3
	
	# Has heal buff - needs heavy attack to interrupt
	buff_chance = 0.15
	buff_duration = 1.5  # Longer duration, gives player time to interrupt
	available_buffs = ["heal"]
	
	# All directions
	available_attacks = ["left", "right", "overhead"]
	
	super._ready()


func choose_attack() -> String:
	# First choose direction
	current_attack_type = available_attacks[randi() % available_attacks.size()]
	
	# Then choose animation variant for that direction
	var variants: Array = attack_variants[current_attack_type]
	current_attack_animation = variants[randi() % variants.size()]
	
	return current_attack_type


func get_attack_animation() -> String:
	return current_attack_animation


func get_telegraph_animation() -> String:
	# Telegraph matches the attack animation
	return "telegraph_" + current_attack_animation


# Override to check for heavy attack requirement on heal
func take_damage(amount: int) -> void:
	var actual_damage: int = int(amount * get_damage_reduction())
	actual_damage = max(1, actual_damage)
	
	current_hp -= actual_damage
	current_hp = max(0, current_hp)
	
	# Only interrupt heal if heavy attack (damage >= 2)
	if is_buffing() and current_buff_type == "heal":
		if amount >= 2:  # Heavy attack
			interrupt_buff()
			print("Heal interrupted by heavy attack!")
		else:
			print("Light attack can't interrupt heal!")
			# Still take damage but don't interrupt
			if current_hp <= 0:
				if current_phase < max_phases:
					trigger_phase_transition()
				else:
					state_machine.change_state("DieState")
			return  # Don't go to hit state during heal
	elif is_buffing():
		interrupt_buff()
	
	if current_hp <= 0:
		if current_phase < max_phases:
			trigger_phase_transition()
		else:
			state_machine.change_state("DieState")
	else:
		state_machine.change_state("HitState")


func _on_phase_changed() -> void:
	match current_phase:
		2:
			telegraph_duration = 0.4
			idle_duration_min = 0.8
			idle_duration_max = 1.5
			buff_chance = 0.2
			
		3:
			telegraph_duration = 0.3
			idle_duration_min = 0.5
			idle_duration_max = 1.0
			attack_damage = 2
			buff_chance = 0.25
			buff_duration = 1.2
			
			_update_hitbox_damage()
	
	base_telegraph_duration = telegraph_duration
	base_idle_duration_min = idle_duration_min
	base_idle_duration_max = idle_duration_max
	base_attack_damage = attack_damage
