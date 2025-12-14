extends State

var buff_timer: float = 0.0
var buff_type: String = ""
var enemy: Enemy
var is_buffing: bool = false


func enter() -> void:
	enemy = player
	buff_timer = 0.0
	is_buffing = true
	
	# Choose and start buff
	buff_type = enemy.choose_buff()
	enemy.start_buff(buff_type)
	
	# Play buff animation
	match buff_type:
		"heal":
			if enemy.anim_player.has_animation("buff_heal"):
				enemy.anim_player.play("buff_heal")
		"speed_up":
			if enemy.anim_player.has_animation("buff_speed"):
				enemy.anim_player.play("buff_speed")
		"power_up":
			if enemy.anim_player.has_animation("buff_power"):
				enemy.anim_player.play("buff_power")
		"shield":
			if enemy.anim_player.has_animation("buff_shield"):
				enemy.anim_player.play("buff_shield")
		_:
			if enemy.anim_player.has_animation("buff_generic"):
				enemy.anim_player.play("buff_generic")


func update(delta: float) -> void:
	buff_timer += delta
	
	if buff_timer >= enemy.buff_duration:
		# Buff completed successfully
		enemy.complete_buff()
		transitioned.emit(self, "IdleState")


func exit() -> void:
	is_buffing = false
