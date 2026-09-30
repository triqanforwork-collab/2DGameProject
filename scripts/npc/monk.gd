extends CharacterBody2D

@onready var interaction_area: Area2D = $InteractionArea


func _ready() -> void:
	interaction_area.body_entered.connect(_on_interaction_area_body_entered)
	interaction_area.body_exited.connect(_on_interaction_area_body_exited)


func interact(_player: Node) -> void:
	var panel := get_tree().get_first_node_in_group("energy_stone_panel")
	if panel == null:
		push_error("Monk could not find the Energy Stone panel.")
		return

	panel.call("open_panel")


func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("register_interactable"):
		body.register_interactable(self)


func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("unregister_interactable"):
		body.unregister_interactable(self)
