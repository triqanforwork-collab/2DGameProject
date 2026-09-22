extends Area2D

@export_multiline var dialog_message := "Bạn có muốn quay về Main Area không?"
@export_file("*.tscn") var target_scene_path := "res://scenes/maps/main.tscn"

@onready var interaction_prompt: Label = $InteractionPrompt

var player_in_range := false
var interaction_in_progress := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	interaction_prompt.visible = false

	if not ResourceLoader.exists(target_scene_path):
		push_error("Return whirlpool target scene does not exist: %s" % target_scene_path)


func _unhandled_input(event: InputEvent) -> void:
	if not player_in_range or interaction_in_progress:
		return

	if event.is_action_pressed("return_to_main"):
		get_viewport().set_input_as_handled()
		_open_confirmation_dialog()


func _open_confirmation_dialog() -> void:
	var dialog := get_tree().get_first_node_in_group("confirmation_dialog")
	if dialog == null:
		push_error("Return whirlpool could not find the shared confirmation dialog.")
		return

	var callback := Callable(self, "_on_dialog_choice_made")
	dialog.connect("choice_made", callback, CONNECT_ONE_SHOT)
	var opened := bool(dialog.call("open_dialog", dialog_message))
	if not opened:
		if dialog.is_connected("choice_made", callback):
			dialog.disconnect("choice_made", callback)
		return

	interaction_in_progress = true
	interaction_prompt.visible = false


func _on_dialog_choice_made(accepted: bool) -> void:
	interaction_in_progress = false
	interaction_prompt.visible = player_in_range

	if accepted:
		SceneLoader.change_scene(target_scene_path)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	player_in_range = true
	if not interaction_in_progress:
		interaction_prompt.visible = true


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	player_in_range = false
	interaction_prompt.visible = false