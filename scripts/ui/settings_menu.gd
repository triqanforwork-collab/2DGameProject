extends Control

const MAIN_MENU_SCENE_PATH := "res://scenes/ui/MainMenu.tscn"

@onready var settings_button: TextureButton = $SettingsButton
@onready var overlay: ColorRect = $Overlay
@onready var close_button: TextureButton = $Overlay/SettingsPanel/InnerMargin/Content/Header/CloseButton
@onready var music_toggle: CheckButton = $Overlay/SettingsPanel/InnerMargin/Content/MusicToggle
@onready var sfx_toggle: CheckButton = $Overlay/SettingsPanel/InnerMargin/Content/SFXToggle
@onready var main_menu_button: Button = $Overlay/SettingsPanel/InnerMargin/Content/MainMenuButton
@onready var exit_button: Button = $Overlay/SettingsPanel/InnerMargin/Content/ExitButton

var was_tree_paused: bool = false


func _ready() -> void:
	settings_button.pressed.connect(open_settings)
	close_button.pressed.connect(close_settings)
	music_toggle.toggled.connect(SettingsManager.set_music_enabled)
	sfx_toggle.toggled.connect(SettingsManager.set_sfx_enabled)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	SettingsManager.music_enabled_changed.connect(_on_music_enabled_changed)
	SettingsManager.sfx_enabled_changed.connect(_on_sfx_enabled_changed)

	overlay.visible = false
	_sync_audio_toggles()


func open_settings() -> void:
	if overlay.visible:
		return

	was_tree_paused = get_tree().paused
	_sync_audio_toggles()
	overlay.visible = true
	get_tree().paused = true
	close_button.grab_focus()


func close_settings() -> void:
	if not overlay.visible:
		return

	overlay.visible = false
	get_tree().paused = was_tree_paused
	settings_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if overlay.visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_settings()


func _exit_tree() -> void:
	if overlay != null and overlay.visible:
		get_tree().paused = was_tree_paused


func _sync_audio_toggles() -> void:
	music_toggle.set_pressed_no_signal(SettingsManager.music_enabled)
	sfx_toggle.set_pressed_no_signal(SettingsManager.sfx_enabled)


func _on_music_enabled_changed(enabled: bool) -> void:
	music_toggle.set_pressed_no_signal(enabled)


func _on_sfx_enabled_changed(enabled: bool) -> void:
	sfx_toggle.set_pressed_no_signal(enabled)


func _on_main_menu_pressed() -> void:
	overlay.visible = false
	get_tree().paused = false
	SceneLoader.change_scene(MAIN_MENU_SCENE_PATH)

func _on_exit_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()
