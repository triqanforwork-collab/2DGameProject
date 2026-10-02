extends Node

signal music_enabled_changed(enabled: bool)
signal sfx_enabled_changed(enabled: bool)

const SETTINGS_PATH := "user://settings.cfg"
const AUDIO_SECTION := "audio"
const LEGACY_SOUND_ENABLED_KEY := "sound_enabled"
const MUSIC_ENABLED_KEY := "music_enabled"
const SFX_ENABLED_KEY := "sfx_enabled"

var music_enabled := true
var sfx_enabled := true


func _ready() -> void:
	_load_settings()
	_apply_audio_settings()


func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
	_set_bus_muted(&"Music", not enabled)
	_save_settings()
	music_enabled_changed.emit(enabled)


func set_sfx_enabled(enabled: bool) -> void:
	sfx_enabled = enabled
	_set_bus_muted(&"SFX", not enabled)
	_save_settings()
	sfx_enabled_changed.emit(enabled)


func _apply_audio_settings() -> void:
	_set_bus_muted(&"Music", not music_enabled)
	_set_bus_muted(&"SFX", not sfx_enabled)


func _set_bus_muted(bus_name: StringName, muted: bool) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		push_warning("SettingsManager could not find the %s audio bus." % bus_name)
		return
	AudioServer.set_bus_mute(bus_index, muted)


func _load_settings() -> void:
	var config := ConfigFile.new()
	var load_error := config.load(SETTINGS_PATH)
	if load_error != OK:
		return

	var legacy_enabled := bool(config.get_value(AUDIO_SECTION, LEGACY_SOUND_ENABLED_KEY, true))
	music_enabled = bool(config.get_value(AUDIO_SECTION, MUSIC_ENABLED_KEY, legacy_enabled))
	sfx_enabled = bool(config.get_value(AUDIO_SECTION, SFX_ENABLED_KEY, legacy_enabled))


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value(AUDIO_SECTION, MUSIC_ENABLED_KEY, music_enabled)
	config.set_value(AUDIO_SECTION, SFX_ENABLED_KEY, sfx_enabled)
	var save_error := config.save(SETTINGS_PATH)
	if save_error != OK:
		push_warning("SettingsManager could not save audio settings: %s" % save_error)
