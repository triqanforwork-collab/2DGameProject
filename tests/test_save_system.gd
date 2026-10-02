extends SceneTree

const TEST_PATH := "user://codex_save_test.json"


func _init() -> void:
	call_deferred(&"run_test")


func run_test() -> void:
	assert(load("res://scenes/ui/FinalSummary.tscn") != null)
	assert(load("res://scenes/ui/MainMenu.tscn") != null)

	var manager = load("res://scripts/managers/save_manager.gd").new()
	root.add_child(manager)
	assert(manager._write_json(TEST_PATH, {"version": 1, "value": 42}))
	assert(int(manager._read_versioned_json(TEST_PATH).get("value", 0)) == 42)
	assert(manager._is_better_run(
		{"elapsed_seconds": 60, "deaths": 2, "upgrades": 1},
		{"elapsed_seconds": 70, "deaths": 0, "upgrades": 5}
	))
	var progression = load("res://scripts/managers/progression_manager.gd").new()
	root.add_child(progression)
	progression.stone_energy[&"water"] = 75
	progression.defeated_bosses[&"water"] = true
	progression.stat_upgrade_levels[&"water"] = 2
	var progression_data: Dictionary = progression.get_save_data()
	progression.reset_progression()
	progression.load_save_data(progression_data)
	assert(progression.get_stone_energy(&"water") == 75)
	assert(progression.is_boss_defeated(&"water"))
	assert(progression.get_stat_upgrade_level(&"water") == 2)

	for suffix in ["", ".tmp", ".bak"]:
		manager._remove_save_file(TEST_PATH + suffix)
	print("Save system smoke test passed.")
	quit()
