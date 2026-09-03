extends Control

const HUB_SCENE_PATH := "res://scenes/hub/Hub.tscn"
const BACKGROUND_BASE_ZOOM := 1.06
const BACKGROUND_ZOOM_RANGE := 0.012
const BACKGROUND_DRIFT_RANGE := Vector2(12.0, 8.0)
const BACKGROUND_DRIFT_SPEED := Vector2(0.32, 0.24)

enum ConfirmAction {
	NONE,
	NEW_GAME,
	EXIT_GAME,
}

@onready var background: TextureRect = $Background
@onready var confirm_overlay: Control = $ConfirmOverlay
@onready var message_label: Label = $ConfirmOverlay/ConfirmPanel/DialogLayout/MessageLabel

var background_base_position := Vector2.ZERO
var current_confirm_action: ConfirmAction = ConfirmAction.NONE


func _ready() -> void:
	hide_confirmation()
	await get_tree().process_frame
	setup_background_motion()


func _process(_delta: float) -> void:
	animate_background()


func setup_background_motion() -> void:
	background_base_position = background.position
	background.pivot_offset = background.size * 0.5


func animate_background() -> void:
	var time := Time.get_ticks_msec() / 1000.0
	var zoom := BACKGROUND_BASE_ZOOM + sin(time * 0.45) * BACKGROUND_ZOOM_RANGE
	var drift := Vector2(
		sin(time * BACKGROUND_DRIFT_SPEED.x) * BACKGROUND_DRIFT_RANGE.x,
		cos(time * BACKGROUND_DRIFT_SPEED.y) * BACKGROUND_DRIFT_RANGE.y
	)

	background.scale = Vector2.ONE * zoom
	background.position = background_base_position + drift


func _on_new_game_pressed() -> void:
	show_confirmation("Bạn có muốn bắt đầu lại từ đầu không?", ConfirmAction.NEW_GAME)


func _on_continue_pressed() -> void:
	continue_game()


func _on_exit_pressed() -> void:
	show_confirmation("Bạn có muốn thoát game không?", ConfirmAction.EXIT_GAME)


func show_confirmation(message: String, action: ConfirmAction) -> void:
	current_confirm_action = action
	message_label.text = message
	confirm_overlay.visible = true


func hide_confirmation() -> void:
	current_confirm_action = ConfirmAction.NONE
	confirm_overlay.visible = false


func _on_confirm_yes_pressed() -> void:
	var confirmed_action: ConfirmAction = current_confirm_action
	hide_confirmation()

	match confirmed_action:
		ConfirmAction.NEW_GAME:
			new_game()
		ConfirmAction.EXIT_GAME:
			exit_game()


func _on_confirm_no_pressed() -> void:
	hide_confirmation()


func new_game() -> void:
	# Later: reset old save data, reset progression, create a new save, then enter the hub.
	get_tree().change_scene_to_file(HUB_SCENE_PATH)


func continue_game() -> void:
	# Later: load the saved scene, player position, and progression before continuing.
	get_tree().change_scene_to_file(HUB_SCENE_PATH)


func exit_game() -> void:
	get_tree().quit()
