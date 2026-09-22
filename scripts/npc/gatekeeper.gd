extends CharacterBody2D

@export var gate_enabled := false
@export_multiline var dialog_message := "Bạn có muốn di chuyển đến Region này không?"
@export_file("*.tscn") var target_scene_path := ""

@onready var interaction_area: Area2D = $InteractionArea

var interaction_in_progress := false


func _ready() -> void:
	interaction_area.body_entered.connect(_on_interaction_area_body_entered)
	interaction_area.body_exited.connect(_on_interaction_area_body_exited)

	if gate_enabled and not ResourceLoader.exists(target_scene_path):
		push_error("Gatekeeper target scene does not exist: %s" % target_scene_path)


func interact(_player: Node) -> void:
	if not gate_enabled or interaction_in_progress:
		return

	var dialog := get_tree().get_first_node_in_group("confirmation_dialog")
	if dialog == null:
		push_error("Gatekeeper could not find the shared confirmation dialog.")
		return

	var callback := Callable(self, "_on_dialog_choice_made")
	dialog.connect("choice_made", callback, CONNECT_ONE_SHOT)
	var opened := bool(dialog.call("open_dialog", dialog_message))
	if not opened:
		if dialog.is_connected("choice_made", callback):
			dialog.disconnect("choice_made", callback)
		return

	interaction_in_progress = true


func _on_dialog_choice_made(accepted: bool) -> void:
	interaction_in_progress = false
	if accepted:
		SceneLoader.change_scene(target_scene_path)


func _on_interaction_area_body_entered(body: Node2D) -> void:
	if not gate_enabled or not body.is_in_group("player"):
		return

	if body.has_method("register_interactable"):
		body.register_interactable(self)


func _on_interaction_area_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if body.has_method("unregister_interactable"):
		body.unregister_interactable(self)