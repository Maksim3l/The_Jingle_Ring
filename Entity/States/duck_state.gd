extends State

var is_ducking: bool = false

func enter() -> void:
	is_ducking = true
	player.set_hurtboxes(true, true, false)  # Disable overhead hurtbox
	player.anim_player.play("duck")
	player.anim_player.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "duck" and is_ducking:
		transitioned.emit(self, "IdleState")

func exit() -> void:
	is_ducking = false
	player.set_hurtboxes(true, true, true)  # Re-enable all
	
	if player.anim_player.animation_finished.is_connected(_on_animation_finished):
		player.anim_player.animation_finished.disconnect(_on_animation_finished)
