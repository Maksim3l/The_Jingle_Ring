extends Node

func _ready() -> void:
	print("=== INPUT DEBUG ACTIVE ===")
	print("Testing if input actions are defined...")
	
	var actions = ["dodge_left", "dodge_right", "duck", "attack_light", "attack_heavy", "pause"]
	for action in actions:
		if InputMap.has_action(action):
			print("  [OK] Action '%s' is defined" % action)
		else:
			print("  [MISSING] Action '%s' is NOT defined!" % action)
	
	print("===========================")


func _input(event: InputEvent) -> void:
	if event.is_pressed() and not event.is_echo():
		if event is InputEventKey:
			print("[INPUT] Key pressed: %s (scancode: %d)" % [OS.get_keycode_string(event.keycode), event.keycode])
		elif event is InputEventMouseButton:
			print("[INPUT] Mouse button: %d" % event.button_index)
		elif event is InputEventJoypadButton:
			print("[INPUT] Joypad button: %d" % event.button_index)
		
		# Check which actions this matches
		for action in ["dodge_left", "dodge_right", "duck", "attack_light", "attack_heavy", "pause"]:
			if InputMap.has_action(action) and event.is_action_pressed(action):
				print("  -> Matches action: %s" % action)
