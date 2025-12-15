extends State

var is_left: bool = true
var is_attacking: bool = false

@export var heavy_damage_multiplier: float = 4.0

func enter() -> void:
	player.set_hurtboxes(true, true, true)
	is_attacking = true
	
	# Cycle between left and right
	owner.play_attack_sound()
	if is_left:
		player.anim_player.play("attack_heavy_left")
	else:
		player.anim_player.play("attack_heavy_right")
	
	is_left = not is_left
	
	# Enable hitbox with heavy damage
	player.hitbox_shape.disabled = false
	player.hitbox.set_meta("damage", int(player.base_damage * heavy_damage_multiplier))
	player.hitbox.set_meta("attack_type", "heavy")
	
	player.anim_player.animation_finished.connect(_on_animation_finished)

func update(_delta: float) -> void:
	# Input blocked during attack
	pass

func _on_animation_finished(anim_name: String) -> void:
	if anim_name.begins_with("attack_heavy") and is_attacking:
		transitioned.emit(self, "IdleState")

func exit() -> void:
	is_attacking = false
	player.hitbox_shape.disabled = true
	player.hitbox.set_meta("damage", player.base_damage)
	
	if player.anim_player.animation_finished.is_connected(_on_animation_finished):
		player.anim_player.animation_finished.disconnect(_on_animation_finished)
