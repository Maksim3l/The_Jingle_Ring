extends State

var is_dodging: bool = false


func enter() -> void:
	is_dodging = true
	player.set_hurtboxes(true, false, true)
	
	player.sprite.flip_h = false
	player.anim_player.play("dodge_left")
	
	player.anim_player.animation_finished.connect(_on_animation_finished)
	print("[DODGE] Left dodge started - RIGHT hurtbox disabled")


func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "dodge_left" and is_dodging:
		transitioned.emit(self, "IdleState")


func exit() -> void:
	is_dodging = false
	player.set_hurtboxes(true, true, true)
	
	if player.anim_player.animation_finished.is_connected(_on_animation_finished):
		player.anim_player.animation_finished.disconnect(_on_animation_finished)
