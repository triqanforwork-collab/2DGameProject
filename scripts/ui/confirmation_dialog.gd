extends Control

signal choice_made(accepted: bool)
signal option_selected(option_index: int)

@onready var message_label: Label = $Center/Panel/Margin/DialogLayout/MessageLabel
@onready var yes_button: Button = $Center/Panel/Margin/DialogLayout/DialogButtons/YesButton
@onready var no_button: Button = $Center/Panel/Margin/DialogLayout/DialogButtons/NoButton
@onready var third_button: Button = $Center/Panel/Margin/DialogLayout/DialogButtons/ThirdButton

var is_open := false
var escape_enabled := true


func _ready() -> void:
	visible = false


func open_dialog(
	message: String,
	yes_text: String = "Yes",
	no_text: String = "No",
	can_cancel_with_escape: bool = true,
	third_text: String = ""
) -> bool:
	if is_open:
		return false

	is_open = true
	escape_enabled = can_cancel_with_escape
	message_label.text = message
	yes_button.text = yes_text
	no_button.text = no_text
	third_button.text = third_text
	third_button.visible = not third_text.is_empty()
	visible = true
	get_tree().paused = true
	yes_button.grab_focus()
	return true


func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return

	if escape_enabled and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		finish_dialog(1)


func _on_yes_button_pressed() -> void:
	finish_dialog(0)


func _on_no_button_pressed() -> void:
	finish_dialog(1)


func _on_third_button_pressed() -> void:
	finish_dialog(2)


func finish_dialog(option_index: int) -> void:
	if not is_open:
		return

	is_open = false
	visible = false
	get_tree().paused = false
	option_selected.emit(option_index)
	if option_index <= 1:
		choice_made.emit(option_index == 0)


func _exit_tree() -> void:
	if is_open and get_tree() != null:
		get_tree().paused = false