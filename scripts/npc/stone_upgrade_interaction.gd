extends Area2D

@export_enum("water", "earth", "light", "air", "life") var stone_id := "water"


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func interact(_player: Node) -> void:
	var panel := get_tree().get_first_node_in_group("stat_upgrade_panel")
	if panel == null:
		push_error("Energy Stone could not find the stat upgrade panel.")
		return
	panel.call("open_for_stone", StringName(stone_id))


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("register_interactable"):
		body.register_interactable(self)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("unregister_interactable"):
		body.unregister_interactable(self)
