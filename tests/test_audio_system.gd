extends SceneTree


func _init() -> void:
	var manager = load("res://scripts/managers/audio_manager.gd").new()
	for file_name in manager.SFX.values():
		assert(load(manager.SFX_ROOT + str(file_name)) is AudioStream)
	var region_controller = load("res://scenes/maps/RegionEncounterController.tscn").instantiate()
	assert(region_controller.get_node("CombatMusic").stream is AudioStream)
	assert(region_controller.get_node("CombatMusic").autoplay)
	region_controller.free()
	var final_summary = load("res://scenes/ui/FinalSummary.tscn").instantiate()
	assert(final_summary.get_node("BackgroundMusic").stream is AudioStream)
	final_summary.free()
	var settings_menu = load("res://scenes/ui/SettingsMenu.tscn").instantiate()
	assert(settings_menu.has_node("Overlay/SettingsPanel/InnerMargin/Content/MusicToggle"))
	assert(settings_menu.has_node("Overlay/SettingsPanel/InnerMargin/Content/SFXToggle"))
	settings_menu.free()
	print("Audio system smoke test passed with %d SFX." % manager.SFX.size())
	manager.free()
	quit()
