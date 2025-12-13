extends Node
## SceneManager responsibilities:
## - Scene transitions with fade effects
## - Creates and manages a transition overlay (CanvasLayer + ColorRect)

signal transition_started()
signal transition_midpoint()
signal transition_finished()
signal fade_to_black_finished()
signal fade_from_black_finished()

@export var fade_duration: float = 0.5
@export var transition_layer: int = 100

var _canvas_layer: CanvasLayer
var _color_rect: ColorRect
var _tween: Tween
var is_transitioning: bool = false


func _ready() -> void:
	_create_transition_overlay()


func _create_transition_overlay() -> void:
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.name = "TransitionLayer"
	_canvas_layer.layer = transition_layer
	add_child(_canvas_layer)
	
	_color_rect = ColorRect.new()
	_color_rect.name = "FadeRect"
	_color_rect.color = Color(0, 0, 0, 0)
	_color_rect.anchors_preset = Control.PRESET_FULL_RECT
	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas_layer.add_child(_color_rect)


func transition_to(scene_path: String) -> void:
	if is_transitioning:
		push_warning("SceneManager: Transition already in progress!")
		return
	
	is_transitioning = true
	transition_started.emit()
	
	await fade_to_black()
	
	transition_midpoint.emit()
	_change_scene(scene_path)
	
	await get_tree().process_frame
	await fade_from_black()
	
	is_transitioning = false
	transition_finished.emit()


func fade_to_black(duration: float = -1.0) -> void:
	if duration < 0:
		duration = fade_duration
	
	_kill_tween()
	_color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	_tween = create_tween()
	_tween.tween_property(_color_rect, "color:a", 1.0, duration)
	await _tween.finished
	
	fade_to_black_finished.emit()


func fade_from_black(duration: float = -1.0) -> void:
	if duration < 0:
		duration = fade_duration
	
	_kill_tween()
	
	_tween = create_tween()
	_tween.tween_property(_color_rect, "color:a", 0.0, duration)
	await _tween.finished
	
	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_from_black_finished.emit()


func fade_to_white(duration: float = -1.0) -> void:
	if duration < 0:
		duration = fade_duration
	
	_kill_tween()
	_color_rect.color = Color(1, 1, 1, 0)
	_color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	_tween = create_tween()
	_tween.tween_property(_color_rect, "color:a", 1.0, duration)
	await _tween.finished


func fade_from_white(duration: float = -1.0) -> void:
	if duration < 0:
		duration = fade_duration
	
	_kill_tween()
	
	_tween = create_tween()
	_tween.tween_property(_color_rect, "color:a", 0.0, duration)
	await _tween.finished
	
	_color_rect.color = Color(0, 0, 0, 0)
	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_black() -> void:
	_kill_tween()
	_color_rect.color = Color(0, 0, 0, 1)
	_color_rect.mouse_filter = Control.MOUSE_FILTER_STOP


func set_clear() -> void:
	_kill_tween()
	_color_rect.color = Color(0, 0, 0, 0)
	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _change_scene(scene_path: String) -> void:
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("SceneManager: Failed to change scene to '%s'. Error: %d" % [scene_path, error])


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = null


func reload_current_scene() -> void:
	var current_scene := get_tree().current_scene
	if current_scene:
		await transition_to(current_scene.scene_file_path)
	else:
		push_error("SceneManager: No current scene to reload!")


func change_scene_instant(scene_path: String) -> void:
	_change_scene(scene_path)
