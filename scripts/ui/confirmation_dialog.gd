extends Control

signal choice_made(accepted: bool)

@onready var message_label: Label = $Center/Panel/Margin/DialogLayout/MessageLabel
@onready var yes_button: Button = $Center/Panel/Margin/DialogLayout/DialogButtons/YesButton
@onready var no_button: Button = $Center/Panel/Margin/DialogLayout/DialogButtons/NoButton

var is_open := false
var escape_enabled := true


func _ready() -> void:
	visible = false


func open_dialog(
	message: String,
	yes_text: String = "Yes",
	no_text: String = "No",
	can_cancel_with_escape: bool = true
) -> bool:
	if is_open:
		return false

	is_open = true
	escape_enabled = can_cancel_with_escape
	message_label.text = message
	yes_button.text = yes_text
	no_button.text = no_text
	visible = true
	get_tree().paused = true
	yes_button.grab_focus()
	return true


func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return

	if escape_enabled and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		finish_dialog(false)


func _on_yes_button_pressed() -> void:
	finish_dialog(true)


func _on_no_button_pressed() -> void:
	finish_dialog(false)


func finish_dialog(accepted: bool) -> void:
	if not is_open:
		return

	is_open = false
	visible = false
	get_tree().paused = false
	choice_made.emit(accepted)


func _exit_tree() -> void:
	if is_open and get_tree() != null:
		get_tree().paused = false