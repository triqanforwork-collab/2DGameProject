extends Control

@onready var title_label: Label = $Center/Panel/Margin/Content/TitleLabel
@onready var reward_label: Label = $Center/Panel/Margin/Content/RewardLabel
@onready var progress_bar: ProgressBar = $Center/Panel/Margin/Content/ProgressBar
@onready var progress_label: Label = $Center/Panel/Margin/Content/ProgressLabel
@onready var boss_label: Label = $Center/Panel/Margin/Content/BossLabel
@onready var carried_label: Label = $Center/Panel/Margin/Content/CarriedLabel
@onready var status_label: Label = $Center/Panel/Margin/Content/StatusLabel
@onready var deposit_button: Button = $Center/Panel/Margin/Content/Buttons/DepositButton

var is_open := false
var notice := ""


func _ready() -> void:
	visible = false
	deposit_button.pressed.connect(_on_deposit_pressed)
	$Center/Panel/Margin/Content/Buttons/CloseButton.pressed.connect(close_panel)


func open_panel() -> void:
	if is_open:
		return

	var activating_stone := ProgressionManager.get_current_stone_id()
	if ProgressionManager.try_activate_current_stone():
		notice = _get_activation_notice(activating_stone)

	is_open = true
	visible = true
	get_tree().paused = true
	_refresh()
	deposit_button.grab_focus()


func close_panel() -> void:
	if not is_open:
		return

	is_open = false
	visible = false
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if is_open and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_panel()


func _on_deposit_pressed() -> void:
	var result := ProgressionManager.deposit_to_current_stone(EnergyManager.carried_energy)
	var deposited := int(result.get("deposited", 0))
	var stone_id := result.get("stone_id", &"") as StringName
	if bool(result.get("activated", false)):
		notice = _get_activation_notice(stone_id)
	elif deposited > 0:
		AudioManager.play_sfx(&"energy_pickup", 0.8, -2.0)
		notice = "Đã nộp %d Energy." % deposited
	else:
		AudioManager.play_sfx(&"denied")
		notice = "Không có Energy để nộp."
	_refresh()


func _refresh() -> void:
	var stone_id := ProgressionManager.get_current_stone_id()
	if stone_id == &"":
		title_label.text = "Năm Viên Đá Đã Thức Tỉnh"
		reward_label.text = "Cây Nguyên Sinh đã được phục hồi hoàn toàn."
		progress_bar.max_value = 1
		progress_bar.value = 1
		progress_label.text = "Hoàn thành"
		boss_label.text = "Tất cả Boss đã bị đánh bại"
		carried_label.text = "Energy đang mang: %d" % EnergyManager.carried_energy
		status_label.text = notice
		deposit_button.disabled = true
		deposit_button.text = "Đã hoàn thành"
		return

	var data := ProgressionManager.get_stone_data(stone_id)
	var current_energy := ProgressionManager.get_stone_energy(stone_id)
	var required_energy := ProgressionManager.get_required_energy(stone_id)
	var remaining_energy := maxi(required_energy - current_energy, 0)
	var boss_defeated := ProgressionManager.is_boss_defeated(stone_id)
	var deposit_amount := mini(EnergyManager.carried_energy, remaining_energy)

	title_label.text = str(data.get("display_name", "Energy Stone"))
	reward_label.text = str(data.get("reward_description", ""))
	progress_bar.max_value = required_energy
	progress_bar.value = current_energy
	progress_label.text = "%d / %d Energy" % [current_energy, required_energy]
	boss_label.text = "%s: %s" % [
		str(data.get("boss_name", "Boss")),
		"Đã đánh bại" if boss_defeated else "Chưa đánh bại",
	]
	carried_label.text = "Energy đang mang: %d" % EnergyManager.carried_energy
	status_label.text = notice if not notice.is_empty() else _get_status_text(remaining_energy, boss_defeated)
	deposit_button.disabled = deposit_amount <= 0
	deposit_button.text = "Nộp %d Energy" % deposit_amount if deposit_amount > 0 else "Không thể nộp"


func _get_status_text(remaining_energy: int, boss_defeated: bool) -> String:
	if remaining_energy <= 0 and not boss_defeated:
		return "Viên đá đã đủ Energy. Hãy đánh bại Boss tương ứng."
	if remaining_energy > 0 and boss_defeated:
		return "Boss đã bị đánh bại. Cần thêm %d Energy." % remaining_energy
	return "Cần Energy và chiến thắng Boss để kích hoạt viên đá."


func _get_activation_notice(stone_id: StringName) -> String:
	var data := ProgressionManager.get_stone_data(stone_id)
	return "%s đã kích hoạt! %s." % [
		str(data.get("display_name", "Energy Stone")),
		str(data.get("reward_description", "Đã mở khóa phần thưởng")),
	]


func _exit_tree() -> void:
	if is_open and get_tree() != null:
		get_tree().paused = false
