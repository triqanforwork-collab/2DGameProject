extends SceneTree

const BOSSES := {
	"Turtle": "res://scenes/bosses/Water/Turtle.tscn",
	"Panda": "res://scenes/bosses/Earth/Panda.tscn",
	"Minotaur": "res://scenes/bosses/Light/Minotaur.tscn",
	"GiantBat": "res://scenes/bosses/Air/GiantBat.tscn",
	"Troll": "res://scenes/bosses/Life/Troll.tscn",
}


func _init() -> void:
	call_deferred(&"run_test")


func run_test() -> void:
	for boss_name in BOSSES:
		var boss = load(BOSSES[boss_name]).instantiate()
		root.add_child(boss)
		assert(boss.has_method("attack_player"))
		assert(boss.attack_cooldown <= 0.83)
		if boss_name != "Turtle":
			assert(boss.has_method("finish_special"))
			assert(boss.attack_range >= 220.0)
		boss.queue_free()
	var effect = load("res://scripts/effects/sprite_sheet_effect.gd").new()
	root.add_child(effect)
	effect.setup(load("res://assets/effects/bosses/IcePick_64x64.png"), Vector2i(64, 64), 30, 30.0, true)
	await create_timer(0.08).timeout
	assert(effect.region_rect.position.x > 0.0)
	effect.queue_free()
	await process_frame
	print("Remaining boss attack smoke test passed.")
	quit()
