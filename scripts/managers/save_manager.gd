extends Node

const SAVE_VERSION := 1
const SAVE_PATH := "user://savegame.json"
const LEADERBOARD_PATH := "user://leaderboard.json"
const MAX_LEADERBOARD_ENTRIES := 10

var total_energy := 0
var enemies_defeated := 0
var deaths := 0
var elapsed_seconds := 0.0
var run_active := false
var tracking_time := false
var completion_recorded := false


func _process(delta: float) -> void:
	if run_active and tracking_time:
		elapsed_seconds += delta


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()


func start_new_game() -> void:
	_remove_save_file(SAVE_PATH)
	_remove_save_file(SAVE_PATH + ".bak")
	ProgressionManager.reset_progression()
	EnergyManager.reset_energy()
	total_energy = 0
	enemies_defeated = 0
	deaths = 0
	elapsed_seconds = 0.0
	completion_recorded = false
	run_active = true
	tracking_time = true
	save_game()


func record_energy(amount: int) -> void:
	if run_active and amount > 0:
		total_energy += amount


func record_enemy_defeated() -> void:
	if run_active:
		enemies_defeated += 1


func record_death() -> void:
	if run_active:
		deaths += 1
		save_game()


func save_game() -> bool:
	if not run_active:
		return false
	return _write_json(SAVE_PATH, {
		"version": SAVE_VERSION,
		"energy": EnergyManager.carried_energy,
		"progression": ProgressionManager.get_save_data(),
		"stats": _get_stats_data(),
	})


func load_game() -> bool:
	var data := _read_versioned_json(SAVE_PATH)
	if data.is_empty():
		return false
	var progression_data = data.get("progression", {})
	var stats_data = data.get("stats", {})
	if not progression_data is Dictionary or not stats_data is Dictionary:
		return false
	ProgressionManager.load_save_data(progression_data)
	EnergyManager.set_energy(int(data.get("energy", 0)))
	var stats := stats_data as Dictionary
	total_energy = maxi(int(stats.get("total_energy", 0)), 0)
	enemies_defeated = maxi(int(stats.get("enemies_defeated", 0)), 0)
	deaths = maxi(int(stats.get("deaths", 0)), 0)
	elapsed_seconds = maxf(float(stats.get("elapsed_seconds", 0.0)), 0.0)
	completion_recorded = bool(stats.get("completion_recorded", false))
	run_active = true
	tracking_time = true
	return true


func pause_run_timer() -> void:
	tracking_time = false


func has_save_game() -> bool:
	return not _read_versioned_json(SAVE_PATH).is_empty()


func complete_run() -> Dictionary:
	var summary := get_summary()
	if completion_recorded:
		return summary
	completion_recorded = true
	run_active = false
	tracking_time = false
	var entries := get_leaderboard()
	entries.append({
		"completed_at": Time.get_datetime_string_from_system(false, true),
		"elapsed_seconds": int(elapsed_seconds),
		"total_energy": total_energy,
		"enemies_defeated": enemies_defeated,
		"deaths": deaths,
		"upgrades": ProgressionManager.get_completed_upgrade_count(),
	})
	entries.sort_custom(_is_better_run)
	entries = entries.slice(0, mini(entries.size(), MAX_LEADERBOARD_ENTRIES))
	_write_json(LEADERBOARD_PATH, {"version": SAVE_VERSION, "entries": entries})
	run_active = true
	save_game()
	run_active = false
	return summary


func get_summary() -> Dictionary:
	return {
		"total_energy": total_energy,
		"enemies_defeated": enemies_defeated,
		"deaths": deaths,
		"upgrades": ProgressionManager.get_completed_upgrade_count(),
		"max_upgrades": ProgressionManager.get_max_upgrade_count(),
	}


func get_leaderboard() -> Array:
	var data := _read_versioned_json(LEADERBOARD_PATH)
	var saved_entries = data.get("entries", [])
	if not saved_entries is Array:
		return []
	var entries: Array = []
	for entry in saved_entries:
		if entry is Dictionary:
			entries.append(entry)
	return entries.slice(0, mini(entries.size(), MAX_LEADERBOARD_ENTRIES))


func _get_stats_data() -> Dictionary:
	return {
		"total_energy": total_energy,
		"enemies_defeated": enemies_defeated,
		"deaths": deaths,
		"elapsed_seconds": elapsed_seconds,
		"completion_recorded": completion_recorded,
	}


func _is_better_run(a: Dictionary, b: Dictionary) -> bool:
	var a_time := int(a.get("elapsed_seconds", 0))
	var b_time := int(b.get("elapsed_seconds", 0))
	if a_time != b_time:
		return a_time < b_time
	var a_deaths := int(a.get("deaths", 0))
	var b_deaths := int(b.get("deaths", 0))
	if a_deaths != b_deaths:
		return a_deaths < b_deaths
	return int(a.get("upgrades", 0)) > int(b.get("upgrades", 0))


func _read_versioned_json(path: String) -> Dictionary:
	var data := _read_json(path)
	if data.is_empty():
		data = _read_json(path + ".bak")
	if int(data.get("version", 0)) != SAVE_VERSION:
		return {}
	return data


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


func _write_json(path: String, data: Dictionary) -> bool:
	var temporary_path := path + ".tmp"
	var backup_path := path + ".bak"
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		push_warning("Could not open save file: %s" % temporary_path)
		return false
	file.store_string(JSON.stringify(data))
	file.close()

	var absolute_path := ProjectSettings.globalize_path(path)
	var absolute_temporary := ProjectSettings.globalize_path(temporary_path)
	var absolute_backup := ProjectSettings.globalize_path(backup_path)
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(absolute_backup)
	if FileAccess.file_exists(path) and DirAccess.rename_absolute(absolute_path, absolute_backup) != OK:
		DirAccess.remove_absolute(absolute_temporary)
		return false
	if DirAccess.rename_absolute(absolute_temporary, absolute_path) == OK:
		return true
	if FileAccess.file_exists(backup_path):
		DirAccess.rename_absolute(absolute_backup, absolute_path)
	return false


func _remove_save_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
