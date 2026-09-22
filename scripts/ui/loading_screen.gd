extends Control

const DEFAULT_TARGET_SCENE := "res://scenes/ui/MainMenu.tscn"
const MINIMUM_DISPLAY_TIME := 0.75
const PROGRESS_SPEED := 180.0

@onready var progress_bar: ProgressBar = $LoadingContent/ProgressBar
@onready var runners: Array[AnimatedSprite2D] = [
	$LoadingContent/CharacterRow/PaddleShark/AnimatedSprite2D,
	$LoadingContent/CharacterRow/HarpoonShark/AnimatedSprite2D,
	$LoadingContent/CharacterRow/BombFish/AnimatedSprite2D,
	$LoadingContent/CharacterRow/Monk/AnimatedSprite2D,
]

var target_scene_path := ""
var elapsed_time := 0.0
var target_progress := 0.0
var load_finished := false
var is_changing_scene := false


func _ready() -> void:
	for runner in runners:
		runner.play(&"run")

	target_scene_path = SceneLoader.consume_target_scene(DEFAULT_TARGET_SCENE)
	var load_error := ResourceLoader.load_threaded_request(target_scene_path)
	if load_error != OK:
		push_error("Could not start loading scene: %s" % target_scene_path)
		SceneLoader.finish_transition()
		set_process(false)


func _process(delta: float) -> void:
	if is_changing_scene:
		return

	elapsed_time += delta
	update_loading_status()
	progress_bar.value = move_toward(progress_bar.value, target_progress, PROGRESS_SPEED * delta)

	if load_finished and elapsed_time >= MINIMUM_DISPLAY_TIME and progress_bar.value >= 99.9:
		finish_loading()


func update_loading_status() -> void:
	var progress: Array = []
	var status := ResourceLoader.load_threaded_get_status(target_scene_path, progress)

	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			if not progress.is_empty():
				target_progress = clampf(float(progress[0]) * 100.0, 0.0, 95.0)
		ResourceLoader.THREAD_LOAD_LOADED:
			target_progress = 100.0
			load_finished = true
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_error("Could not load scene: %s" % target_scene_path)
			SceneLoader.finish_transition()
			set_process(false)


func finish_loading() -> void:
	if is_changing_scene:
		return

	is_changing_scene = true
	var packed_scene := ResourceLoader.load_threaded_get(target_scene_path) as PackedScene
	if packed_scene == null:
		push_error("Loaded resource is not a PackedScene: %s" % target_scene_path)
		SceneLoader.finish_transition()
		is_changing_scene = false
		return

	SceneLoader.finish_transition()
	get_tree().change_scene_to_packed(packed_scene)
