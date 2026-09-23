extends Node

signal sound_enabled_changed(enabled: bool)

const SETTINGS_PATH := "user://settings.cfg"
const AUDIO_SECTION := "audio"
const SOUND_ENABLED_KEY := "sound_enabled"
const MASTER_BUS_NAME := &"Master"

var sound_enabled: bool = true


func _ready() -> void:
	_load_settings()
	_apply_audio_setting()


func set_sound_enabled(enabled: bool) -> void:
	if sound_enabled == enabled:
		_apply_audio_setting()
		return

	sound_enabled = enabled
	_apply_audio_setting()
	_save_settings()
	sound_enabled_changed.emit(sound_enabled)


func toggle_sound() -> void:
	set_sound_enabled(not sound_enabled)


func _apply_audio_setting() -> void:
	var master_bus_index := AudioServer.get_bus_index(MASTER_BUS_NAME)
	if master_bus_index < 0:
		push_warning("SettingsManager could not find the Master audio bus.")
		return

	AudioServer.set_bus_mute(master_bus_index, not sound_enabled)


func _load_settings() -> void:
	var config := ConfigFile.new()
	var load_error := config.load(SETTINGS_PATH)
	if load_error != OK:
		return

	sound_enabled = bool(config.get_value(
		AUDIO_SECTION,
		SOUND_ENABLED_KEY,
		true
	))


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value(AUDIO_SECTION, SOUND_ENABLED_KEY, sound_enabled)
	var save_error := config.save(SETTINGS_PATH)
	if save_error != OK:
		push_warning("SettingsManager could not save audio settings: %s" % save_error)
