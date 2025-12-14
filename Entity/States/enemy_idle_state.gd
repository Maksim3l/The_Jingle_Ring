extends State

var idle_timer: float = 0.0
var idle_duration: float = 0.0
var enemy: Enemy


func enter() -> void:
	enemy = player  # player is set by state machine, but it's actually the enemy
	
	if enemy.anim_player.has_animation("idle"):
		enemy.anim_player.play("idle")
	
	enemy.disable_all_hitboxes()
	enemy.hide_tells()
	
	idle_duration = enemy.get_random_idle_duration()
	idle_timer = 0.0


func update(delta: float) -> void:
	idle_timer += delta
	
	if idle_timer >= idle_duration:
		# Choose between attack or buff
		var action: String = enemy.choose_action()
		
		if action == "buff":
			transitioned.emit(self, "BuffState")
		else:
			transitioned.emit(self, "TelegraphState")


func exit() -> void:
	pass
