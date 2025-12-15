extends State

var telegraph_timer: float = 0.0
var attack_key: String = ""
var enemy: Enemy
var is_telegraphing: bool = false


func enter() -> void:
	enemy = player  # player is set by state machine, but it's actually the enemy
	telegraph_timer = 0.0
	is_telegraphing = true
	
	# Choose which attack to telegraph (returns attack key like "claw_left")
	attack_key = enemy.choose_attack()
	
	# Play telegraph animation using the new system
	enemy.play_telegraph_animation(attack_key)
	
	# Show tell indicator (still uses attack key, enemy handles animation lookup)
	enemy.show_tell(attack_key)


func update(delta: float) -> void:
	telegraph_timer += delta
	
	if telegraph_timer >= enemy.telegraph_duration:
		# Telegraph complete, execute the attack
		transitioned.emit(self, "AttackState")


func exit() -> void:
	is_telegraphing = false
	enemy.hide_tells()
