extends State

var enemy: Enemy
var is_dying: bool = false
var anim_connected: bool = false


func enter() -> void:
	enemy = player
	is_dying = true
	
	# Disable all collision
	enemy.disable_all_hitboxes()
	if enemy.hurtbox_shape:
		enemy.hurtbox_shape.disabled = true
	
	# Play death animation
	enemy.anim_player.play("die")
	
	# Connect to animation finished
	if not enemy.anim_player.animation_finished.is_connected(_on_animation_finished):
		enemy.anim_player.animation_finished.connect(_on_animation_finished)
		anim_connected = true
	
	# Award knockout score
	GameManager.add_score(GameManager.SCORE_VALUES["knockout"])
	
	# Emit died signal
	enemy.died.emit()


func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "die" and is_dying:
		# Death animation complete - enemy can be removed or hidden
		enemy.visible = false
		# The game controller will handle spawning the next enemy


func exit() -> void:
	# This should rarely be called (terminal state)
	# But support it for phase transitions or revival mechanics
	is_dying = false
	
	if anim_connected and enemy.anim_player.animation_finished.is_connected(_on_animation_finished):
		enemy.anim_player.animation_finished.disconnect(_on_animation_finished)
		anim_connected = false
	
	# Re-enable hurtbox if reviving
	if enemy.hurtbox_shape:
		enemy.hurtbox_shape.disabled = false
