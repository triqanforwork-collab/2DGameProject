extends SceneTree


func _init() -> void:
	ProgressionManager.reset_progression()
	EnergyManager.reset_energy()
	assert(not ProgressionManager.purchase_stat_upgrade(&"water").success)

	ProgressionManager.unlocked_rewards[&"stat_upgrades"] = true
	EnergyManager.add_energy(125)
	for stone_id in ProgressionManager.STONE_ORDER:
		assert(ProgressionManager.purchase_stat_upgrade(stone_id).success)
		assert(ProgressionManager.get_stat_upgrade_level(stone_id) == 1)
	assert(EnergyManager.carried_energy == 0)

	var player := preload("res://scenes/player/Player.tscn").instantiate()
	root.add_child(player)
	assert(player.max_health == 110)
	assert(player.max_mana == 110)
	assert(player.attack_damage == 110)
	assert(player.staff_attack_damage == 9)
	assert(player.heal_amount == 35)
	assert(player.area_attack_damage == 165)
	assert(player.use_mana(10))
	player.update_mana_regeneration(2.0)
	assert(player.mana == 100)
	player.update_mana_regeneration(0.25)
	assert(player.mana == 101)

	print("Stat upgrade smoke test passed.")
	quit()
