extends SceneTree


func _init() -> void:
	var controller := preload("res://scenes/ui/StoneCelebrationController.tscn").instantiate()
	root.add_child(controller)
	controller._on_stone_activated(&"water", &"heal")
	assert(controller.get_node("CelebrationSound").playing)
	assert(controller.get_node("CelebrationLayer/VictoryFireworks").is_playing)
	assert(controller.get_node("BossWarningOverlay").visible)
	assert(controller.get_node("BossWarningOverlay/Overlay/Center/Content/WarningLabel").text == "CHÚC MỪNG!")
	print("Stone celebration smoke test passed.")
	quit()
