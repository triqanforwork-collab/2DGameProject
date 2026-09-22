extends Node

const LOADING_SCREEN_PATH := "res://scenes/ui/LoadingScreen.tscn"

var pending_scene_path := ""
var transition_in_progress := false


func change_scene(scene_path: String) -> void:
	if scene_path.is_empty():
		push_error("SceneLoader received an empty scene path.")
		return

	if not ResourceLoader.exists(scene_path):
		push_error("Scene does not exist: %s" % scene_path)
		return

	if transition_in_progress:
		return

	pending_scene_path = scene_path
	transition_in_progress = true

	var change_error := get_tree().change_scene_to_file(LOADING_SCREEN_PATH)
	if change_error != OK:
		push_error("Could not open Loading Screen.")
		pending_scene_path = ""
		transition_in_progress = false


func consume_target_scene(default_scene_path: String) -> String:
	if pending_scene_path.is_empty():
		return default_scene_path

	var scene_path := pending_scene_path
	pending_scene_path = ""
	return scene_path


func finish_transition() -> void:
	transition_in_progress = false
