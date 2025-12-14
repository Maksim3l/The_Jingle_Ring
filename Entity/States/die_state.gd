extends State

func enter() -> void:
	# Disable all collision - can't be hit when dead
	player.set_hurtboxes(false, false, false)
	player.hitbox_shape.disabled = true
	
	player.anim_player.play("die")
	
	player.anim_player.animation_finished.connect(_on_animation_finished)
	
	# Notify GameManager
	# GameManager.on_player_died()
	# or emit a signal:
	player.died.emit()

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "die":
		# Terminal state - do nothing, wait for game to handle
		pass

func exit() -> void:
	# This should never be called (terminal state)
	# But just in case of revival mechanic:
	if player.anim_player.animation_finished.is_connected(_on_animation_finished):
		player.anim_player.animation_finished.disconnect(_on_animation_finished)

# No update or handle_input - terminal state, no transitions out
