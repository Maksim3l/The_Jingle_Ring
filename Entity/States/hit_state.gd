extends State

@export var recovery_duration: float = 0.3

var timer: float = 0.0
var is_hit: bool = false


func enter() -> void:
	is_hit = true
	timer = 0.0
	
	player.set_hurtboxes(true, true, true)

	if player.last_hit_direction == "right":
		player.anim_player.play("hit_right")
	else:
		player.anim_player.play("hit_left")
	
	player.play_all_hit_feedback()

func update(delta: float) -> void:
	timer += delta
	
	# After recovery duration, transition out
	if timer >= recovery_duration:
		# Check GameManager for HP (not player.health which doesn't exist)
		if GameManager.current_hp <= 0:
			transitioned.emit(self, "DieState")
		else:
			transitioned.emit(self, "IdleState")


func exit() -> void:
	is_hit = false
	player.stop_blood()
