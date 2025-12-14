extends State

var telegraph_timer: float = 0.0
var attack_type: String = ""
var enemy: Enemy
var is_telegraphing: bool = false


func enter() -> void:
	enemy = player  # player is set by state machine, but it's actually the enemy
	telegraph_timer = 0.0
	is_telegraphing = true
	
	# Choose which attack to telegraph
	attack_type = enemy.choose_attack()
	
	# Play telegraph animation based on attack type
	var anim_name: String = "telegraph_" + attack_type
	if enemy.anim_player.has_animation(anim_name):
		enemy.anim_player.play(anim_name)
	elif enemy.anim_player.has_animation("telegraph"):
		enemy.anim_player.play("telegraph")
	# If no telegraph animation exists, just stay in current pose
	
	# Show tell indicator using enemy's method
	enemy.show_tell(attack_type)


func update(delta: float) -> void:
	telegraph_timer += delta
	
	if telegraph_timer >= enemy.telegraph_duration:
		# Telegraph complete, execute the attack
		transitioned.emit(self, "AttackState")


func exit() -> void:
	is_telegraphing = false
	enemy.hide_tells()
