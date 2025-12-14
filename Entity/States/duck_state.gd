extends State

var is_ducking: bool = false

func enter() -> void:
	is_ducking = true
	player.set_hurtboxes(true, true, false)  # Disable overhead hurtbox
	player.anim_player.play("duck")

func handle_input(event: InputEvent) -> void:
	# Return to idle when duck key released
	if event.is_action_released("duck"):
		transitioned.emit(self, "IdleState")

func exit() -> void:
	is_ducking = false
	player.set_hurtboxes(true, true, true)  # Re-enable all
