extends State

var is_dodging: bool = false


func enter() -> void:
	is_dodging = true
	player.set_hurtboxes(false, true, true)
	
	player.anim_player.play("dodge_right")
	
	player.anim_player.animation_finished.connect(_on_animation_finished)
	print("[DODGE] Right dodge started - LEFT hurtbox disabled")


func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "dodge_right" and is_dodging:
		transitioned.emit(self, "IdleState")


func exit() -> void:
	is_dodging = false
	player.sprite.flip_h = false
	player.set_hurtboxes(true, true, true)
	
	if player.anim_player.animation_finished.is_connected(_on_animation_finished):
		player.anim_player.animation_finished.disconnect(_on_animation_finished)
