extends State

## Special heal state for Pariah Scary
## Different from BuffState heal - this is a one-time special ability

var heal_timer: float = 0.0
var enemy: Enemy
var is_healing: bool = false
var heal_duration: float = 2.0  # Time to complete the heal
var heal_amount: int = 0
var anim_connected: bool = false


func enter() -> void:
	enemy = player
	heal_timer = 0.0
	is_healing = true
	
	# Calculate heal amount (heal to 50% of max HP)
	heal_amount = int(enemy.max_hp * 0.5)
	
	# Play heal animation
	enemy.anim_player.play("heal")
	
	# Visual effect - green glow
	_start_heal_glow()
	
	# Connect animation if needed
	if not enemy.anim_player.animation_finished.is_connected(_on_animation_finished):
		enemy.anim_player.animation_finished.connect(_on_animation_finished)
		anim_connected = true


func update(delta: float) -> void:
	heal_timer += delta
	
	if heal_timer >= heal_duration:
		# Heal completed
		_complete_heal()
		transitioned.emit(self, "IdleState")


func _on_animation_finished(anim_name: String) -> void:
	# If animation finishes before timer, still wait for timer
	pass


func _complete_heal() -> void:
	enemy.heal(heal_amount)
	_end_heal_glow()
	print(enemy.name + " healed for " + str(heal_amount) + " HP!")


func _start_heal_glow() -> void:
	var tween = enemy.create_tween()
	tween.set_loops()
	tween.tween_property(enemy.sprite, "modulate", Color.GREEN, 0.3)
	tween.tween_property(enemy.sprite, "modulate", Color.WHITE, 0.3)


func _end_heal_glow() -> void:
	enemy.sprite.modulate = Color.WHITE


func exit() -> void:
	is_healing = false
	_end_heal_glow()
	
	if anim_connected and enemy.anim_player.animation_finished.is_connected(_on_animation_finished):
		enemy.anim_player.animation_finished.disconnect(_on_animation_finished)
		anim_connected = false
