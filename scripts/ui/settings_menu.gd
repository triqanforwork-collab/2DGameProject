extends Control

@onready var settings_button: TextureButton = $SettingsButton
@onready var overlay: ColorRect = $Overlay
@onready var close_button: TextureButton = $Overlay/SettingsPanel/InnerMargin/Content/Header/CloseButton
@onready var sound_toggle: CheckButton = $Overlay/SettingsPanel/InnerMargin/Content/SoundToggle
@onready var exit_button: Button = $Overlay/SettingsPanel/InnerMargin/Content/ExitButton

var was_tree_paused: bool = false


func _ready() -> void:
	settings_button.pressed.connect(open_settings)
	close_button.pressed.connect(close_settings)
	sound_toggle.toggled.connect(_on_sound_toggled)
	exit_button.pressed.connect(_on_exit_pressed)
	SettingsManager.sound_enabled_changed.connect(_on_sound_enabled_changed)

	overlay.visible = false
	sound_toggle.set_pressed_no_signal(SettingsManager.sound_enabled)


func open_settings() -> void:
	if overlay.visible:
		return

	was_tree_paused = get_tree().paused
	sound_toggle.set_pressed_no_signal(SettingsManager.sound_enabled)
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


func _on_sound_toggled(enabled: bool) -> void:
	SettingsManager.set_sound_enabled(enabled)


func _on_sound_enabled_changed(enabled: bool) -> void:
	sound_toggle.set_pressed_no_signal(enabled)


func _on_exit_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()
