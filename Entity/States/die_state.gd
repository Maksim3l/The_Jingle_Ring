extends State


func enter() -> void:
	player.set_hurtboxes(false, false, false)
	player.hitbox_shape.disabled = true

	player.anim_player.play("death")
	
	player.anim_player.animation_finished.connect(_on_animation_finished)
	
	player.died.emit()


func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "death":
		# Terminal state - do nothing, wait for game to handle
		pass


func exit() -> void:
	if player.anim_player.animation_finished.is_connected(_on_animation_finished):
		player.anim_player.animation_finished.disconnect(_on_animation_finished)
