extends State

func enter() -> void:
	player.set_hurtboxes(true, true, true)
	player.anim_player.play("idle")


func handle_input(event: InputEvent) -> void:
	# Dodge and duck inputs - these are defensive actions
	if event.is_action_pressed("dodge_left"):
		transitioned.emit(self, "DodgeLeftState")
		return
	elif event.is_action_pressed("dodge_right"):
		transitioned.emit(self, "DodgeRightState")
		return
	elif event.is_action_pressed("duck"):
		transitioned.emit(self, "DuckState")
		return
	
	# Attack inputs - offensive actions
	if event.is_action_pressed("attack_light"):
		transitioned.emit(self, "AttackLightState")
	elif event.is_action_pressed("attack_heavy"):
		transitioned.emit(self, "AttackHeavyState")
