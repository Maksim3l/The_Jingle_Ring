extends State

@export var stun_duration: float = 0.4

var stun_timer: float = 0.0
var enemy: Enemy
var is_stunned: bool = false


func enter() -> void:
	enemy = player
	stun_timer = 0.0
	is_stunned = true
	
	# Disable hitboxes while stunned
	enemy.disable_all_hitboxes()
	
	# Play hit animation
	enemy.anim_player.play("hit")
	
	# Visual feedback
	enemy.play_hit_feedback()
	
	# Update health bar
	_update_health_bar()


func update(delta: float) -> void:
	stun_timer += delta
	
	if stun_timer >= stun_duration:
		# Check if dead
		if enemy.current_hp <= 0:
			transitioned.emit(self, "DieState")
		else:
			transitioned.emit(self, "IdleState")


func exit() -> void:
	is_stunned = false
	enemy.stop_hit_particles()


func _update_health_bar() -> void:
	var health_bar = enemy.get_node_or_null("HealthBar")
	if health_bar and health_bar is ProgressBar:
		health_bar.value = enemy.get_hp_percentage() * 100.0
