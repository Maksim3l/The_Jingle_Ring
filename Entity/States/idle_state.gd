extends State

func enter() -> void:
	player.set_hurtboxes(true, true, true)
	player.anim_player.play("idle")

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack_light"):
		transitioned.emit(self, "AttackLightState")
	elif event.is_action_pressed("attack_heavy"):
		transitioned.emit(self, "AttackHeavyState")
	elif event.is_action_pressed("dodge_left"):
		transitioned.emit(self, "DodgeLeftState")
	elif event.is_action_pressed("dodge_right"):
		transitioned.emit(self, "DodgeRightState")
	elif event.is_action_pressed("duck"):
		transitioned.emit(self, "DuckState")
