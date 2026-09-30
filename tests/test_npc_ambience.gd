extends SceneTree


func _init() -> void:
	var sheep := preload("res://scenes/npc/Sheep.tscn").instantiate()
	root.add_child(sheep)
	var start: Vector2 = sheep.global_position
	sheep._physics_process(0.1)
	assert(sheep.global_position == start, "Sheep moved before the player approached.")
	assert(sheep.sprite.animation == &"idle")

	var player := Node2D.new()
	player.add_to_group("player")
	sheep._on_player_entered(player)
	assert(sheep.fleeing, "Sheep did not enter flee mode.")
	sheep._physics_process(0.1)
	assert(sheep.global_position != start, "Sheep did not flee from the player.")
	assert(sheep.speech_bubble.visible, "Sheep did not show its speech bubble.")
	assert(not sheep.speech_cooldown.is_stopped(), "Sheep speech cooldown did not start.")

	var worker := preload("res://scenes/npc/WorkerPawn.tscn").instantiate()
	worker.work_animation = "pickaxe"
	root.add_child(worker)
	assert(worker.get_node("AnimatedSprite2D").animation == &"pickaxe")
	worker._on_player_entered(player)
	assert(worker.get_node("AnimatedSprite2D").animation == &"pickaxe_run")
	assert(worker.speech_bubble.visible)
	assert(worker.speech_bubble.text == "I'm sorry!")
	assert(not worker.speech_cooldown.is_stopped())
	worker.global_position = worker.safe_position
	worker._physics_process(0.1)
	assert(worker.get_node("AnimatedSprite2D").animation == &"pickaxe_idle")
	player.global_position = Vector2(500, 500)
	worker._physics_process(0.1)
	assert(not worker.get_node("ReturnDelay").is_stopped())

	var gold_pawn := preload("res://scenes/npc/WorkerPawn.tscn").instantiate()
	gold_pawn.work_animation = "gold"
	gold_pawn.speech_text = "0.o"
	root.add_child(gold_pawn)
	assert(gold_pawn.sprite.animation == &"gold_idle")
	gold_pawn._on_player_entered(player)
	assert(gold_pawn.sprite.animation == &"gold_run")
	assert(gold_pawn.speech_bubble.text == "0.o")
	assert(gold_pawn.speech_bubble.visible)
	print("NPC ambience smoke test passed.")
	quit()
