extends State

var enemy: Enemy
var is_attacking: bool = false
var attack_connected: bool = false


func enter() -> void:
	enemy = player
	is_attacking = true
	attack_connected = false
	
	# Get the attack type that was chosen in telegraph state
	var attack_type: String = enemy.current_attack_type
	
	# Play attack animation
	var anim_name: String = "attack_" + attack_type
	if enemy.anim_player.has_animation(anim_name):
		enemy.anim_player.play(anim_name)
	else:
		enemy.anim_player.play("attack")
	
	# Enable the appropriate hitbox
	enemy.enable_hitbox(attack_type)
	
	# Connect to animation finished
	if not enemy.anim_player.animation_finished.is_connected(_on_animation_finished):
		enemy.anim_player.animation_finished.connect(_on_animation_finished)
		attack_connected = true


func _on_animation_finished(anim_name: String) -> void:
	if anim_name.begins_with("attack") and is_attacking:
		transitioned.emit(self, "IdleState")


func exit() -> void:
	is_attacking = false
	
	# Disable hitboxes
	enemy.disable_all_hitboxes()
	
	# Disconnect signal
	if attack_connected and enemy.anim_player.animation_finished.is_connected(_on_animation_finished):
		enemy.anim_player.animation_finished.disconnect(_on_animation_finished)
		attack_connected = false
