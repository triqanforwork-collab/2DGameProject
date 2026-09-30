extends Control

@onready var title_label: Label = $Center/Panel/Margin/Content/TitleLabel
@onready var stat_label: Label = $Center/Panel/Margin/Content/StatLabel
@onready var level_label: Label = $Center/Panel/Margin/Content/LevelLabel
@onready var bonus_label: Label = $Center/Panel/Margin/Content/BonusLabel
@onready var energy_label: Label = $Center/Panel/Margin/Content/EnergyLabel
@onready var status_label: Label = $Center/Panel/Margin/Content/StatusLabel
@onready var upgrade_button: Button = $Center/Panel/Margin/Content/Buttons/UpgradeButton

var stone_id := &""
var is_open := false
var notice := ""


func _ready() -> void:
	visible = false
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	$Center/Panel/Margin/Content/Buttons/CloseButton.pressed.connect(close_panel)


func open_for_stone(selected_stone_id: StringName) -> void:
	if is_open:
		return
	stone_id = selected_stone_id
	notice = ""
	is_open = true
	visible = true
	get_tree().paused = true
	_refresh()
	upgrade_button.grab_focus()


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


func _on_upgrade_pressed() -> void:
	var result := ProgressionManager.purchase_stat_upgrade(stone_id)
	notice = str(result.get("message", ""))
	_refresh()


func _refresh() -> void:
	var stone_data := ProgressionManager.get_stone_data(stone_id)
	var upgrade_data := ProgressionManager.get_stat_upgrade_data(stone_id)
	var level := ProgressionManager.get_stat_upgrade_level(stone_id)
	var max_level := ProgressionManager.UPGRADE_COSTS.size()
	var cost := ProgressionManager.get_stat_upgrade_cost(stone_id)
	var unlocked := ProgressionManager.is_reward_unlocked(&"stat_upgrades")

	title_label.text = str(stone_data.get("display_name", "Energy Stone"))
	stat_label.text = str(upgrade_data.get("stat_name", "Chỉ số"))
	level_label.text = "Cấp %d / %d" % [level, max_level]
	bonus_label.text = str(upgrade_data.get("bonus_text", ""))
	energy_label.text = "Energy đang mang: %d" % EnergyManager.carried_energy
	status_label.text = notice

	if not unlocked:
		upgrade_button.disabled = true
		upgrade_button.text = "Chưa mở khóa"
		if notice.is_empty():
			status_label.text = "Hãy kích hoạt Air Stone để mở hệ thống nâng chỉ số."
	elif level >= max_level:
		upgrade_button.disabled = true
		upgrade_button.text = "Đã tối đa"
		if notice.is_empty():
			status_label.text = "Chỉ số này đã đạt cấp tối đa."
	else:
		upgrade_button.disabled = EnergyManager.carried_energy < cost
		upgrade_button.text = "Nâng cấp — %d Energy" % cost
		if notice.is_empty():
			status_label.text = "Mỗi lần nâng tiêu Energy đang mang."


func _exit_tree() -> void:
	if is_open and get_tree() != null:
		get_tree().paused = false
