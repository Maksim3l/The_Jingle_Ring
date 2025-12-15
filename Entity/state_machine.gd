extends Node
class_name StateMachine

@export var initial_state: State

var current_state: State
var states: Dictionary = {}


func _ready() -> void:
	# Wait for owner to be ready
	await owner.ready
	
	# Find all child states
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.player = owner
			child.state_machine = self
			child.transitioned.connect(_on_state_transitioned)
	
	# Initialize first state
	if initial_state:
		current_state = initial_state
		current_state.enter()
	
	print("StateMachine initialized with states: ", states.keys())


func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)


func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)


func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)


func change_state(new_state_name: String) -> void:
	var new_state = states.get(new_state_name.to_lower())
	if not new_state:
		push_warning("State not found: " + new_state_name)
		return
	
	if current_state:
		current_state.exit()
	
	current_state = new_state
	current_state.enter()
	print("Changed to state: " + new_state_name)


func _on_state_transitioned(state, new_state_name: String) -> void:
	if state != current_state:
		return
	change_state(new_state_name)
