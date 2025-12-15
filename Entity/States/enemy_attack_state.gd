extends State

var enemy: Enemy
var is_attacking: bool = false
var attack_connected: bool = false


func enter() -> void:
	enemy = player
	is_attacking = true
	attack_connected = false
	
	# Get the attack key that was chosen in telegraph state (e.g., "claw_left")
	var attack_key: String = enemy.current_attack_type
	
	# Play attack animation using the new system
	enemy.play_attack_animation(attack_key)
	
	# Enable the hitbox (direction is looked up from attack registry)
	enemy.enable_hitbox(attack_key)
	
	# Connect to animation finished
	if not enemy.anim_player.animation_finished.is_connected(_on_animation_finished):
		enemy.anim_player.animation_finished.connect(_on_animation_finished)
		attack_connected = true


func _on_animation_finished(_anim_name: String) -> void:
	# Any animation finishing while attacking means we're done
	if is_attacking:
		transitioned.emit(self, "IdleState")


func exit() -> void:
	is_attacking = false
	
	# Disable hitboxes
	enemy.disable_all_hitboxes()
	
	# Disconnect signal
	if attack_connected and enemy.anim_player.animation_finished.is_connected(_on_animation_finished):
		enemy.anim_player.animation_finished.disconnect(_on_animation_finished)
		attack_connected = false
