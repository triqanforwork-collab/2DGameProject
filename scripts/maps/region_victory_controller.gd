extends Node

const MAIN_AREA_SCENE := "res://scenes/maps/main.tscn"
const MAIN_MENU_SCENE := "res://scenes/ui/MainMenu.tscn"

@export_file("*.tscn") var replay_scene_path: String
@export_enum("water", "earth", "light", "air", "life") var region_id := "water"
@export_multiline var victory_message := "Chúc mừng! Bạn đã đánh bại Boss của khu vực này!"

@onready var victory_sound: AudioStreamPlayer = $VictorySound

var victory_handled := false


func _ready() -> void:
	call_deferred("_connect_encounter")


func _connect_encounter() -> void:
	var encounter := get_tree().get_first_node_in_group("region_encounter_controller")
	if encounter != null:
		var callback := Callable(self, "_on_boss_spawned")
		if not encounter.is_connected("boss_spawned", callback):
			encounter.connect("boss_spawned", callback)
	_connect_bosses()


func _connect_bosses() -> void:
	for boss in get_tree().get_nodes_in_group("boss"):
		_connect_boss(boss)


func _connect_boss(boss: Node) -> void:
	if boss == null or not boss.has_signal("defeated"):
		return
	var callback := Callable(self, "_on_boss_defeated")
	if not boss.is_connected("defeated", callback):
		boss.connect("defeated", callback)


func _on_boss_spawned(boss: Node) -> void:
	_connect_boss(boss)


func _on_boss_defeated(_boss: Node) -> void:
	if victory_handled:
		return

	victory_handled = true
	ProgressionManager.mark_boss_defeated(StringName(region_id))
	victory_sound.play()
	await _wait_for_boss_energy()
	_open_victory_dialog()


func _wait_for_boss_energy() -> void:
	await get_tree().process_frame
	while not get_tree().get_nodes_in_group("boss_energy_pickup").is_empty():
		await get_tree().process_frame


func _open_victory_dialog() -> void:
	var dialog := get_tree().get_first_node_in_group("confirmation_dialog")
	if dialog == null:
		push_error("RegionVictoryController could not find a confirmation dialog.")
		return

	if not dialog.option_selected.is_connected(_on_victory_option_selected):
		dialog.option_selected.connect(_on_victory_option_selected, CONNECT_ONE_SHOT)
	var opened: bool = dialog.open_dialog(
		victory_message,
		"Chơi lại màn này",
		"Quay về đảo hồi sinh",
		false,
		"Về Main Menu"
	)
	if opened:
		var fireworks := dialog.get_node_or_null("VictoryFireworks")
		if fireworks != null:
			fireworks.play()
	if not opened and dialog.option_selected.is_connected(_on_victory_option_selected):
		dialog.option_selected.disconnect(_on_victory_option_selected)

func _on_victory_option_selected(option_index: int) -> void:
	var dialog := get_tree().get_first_node_in_group("confirmation_dialog")
	if dialog != null:
		var fireworks := dialog.get_node_or_null("VictoryFireworks")
		if fireworks != null:
			fireworks.stop()

	var destination := get_destination_path(option_index)
	if destination.is_empty():
		return
	SceneLoader.change_scene(destination)


func get_destination_path(option_index: int) -> String:
	match option_index:
		0:
			return replay_scene_path
		1:
			return MAIN_AREA_SCENE
		2:
			return MAIN_MENU_SCENE
		_:
			return ""