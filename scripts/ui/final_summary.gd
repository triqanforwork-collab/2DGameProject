extends Control

const MAIN_MENU_SCENE := "res://scenes/ui/MainMenu.tscn"

@onready var title_label: Label = $Center/Panel/Margin/Content/Title
@onready var summary_label: RichTextLabel = $Center/Panel/Margin/Content/Summary
@onready var leaderboard_label: RichTextLabel = $Center/Panel/Margin/Content/Leaderboard
@onready var leaderboard_button: Button = $Center/Panel/Margin/Content/Buttons/LeaderboardButton
@onready var continue_button: Button = $Center/Panel/Margin/Content/Buttons/ContinueButton
@onready var menu_button: Button = $Center/Panel/Margin/Content/Buttons/MenuButton
@onready var background_music: AudioStreamPlayer = $BackgroundMusic

var has_summary := false
var paused_background_music: AudioStreamPlayer


func _ready() -> void:
	background_music.finished.connect(background_music.play)
	visible = false


func play_music() -> void:
	if not background_music.playing:
		background_music.play()


func open_summary(stats: Dictionary) -> void:
	has_summary = true
	title_label.text = "HÀNH TRÌNH HOÀN TẤT"
	summary_label.text = (
		"[center][font_size=24]Tổng Energy thu được: [color=#ffe36e]%d[/color]\n\n"
		+ "Tổng quái tiêu diệt: [color=#7ee7ff]%d[/color]\n\n"
		+ "Tổng số lần bị hạ: [color=#ff8c8c]%d[/color]\n\n"
		+ "Nâng cấp đã hoàn thành: [color=#9cff9c]%d / %d[/color][/font_size][/center]"
	) % [
		int(stats.get("total_energy", 0)),
		int(stats.get("enemies_defeated", 0)),
		int(stats.get("deaths", 0)),
		int(stats.get("upgrades", 0)),
		int(stats.get("max_upgrades", 0)),
	]
	_show_summary()
	_open()


func open_leaderboard() -> void:
	has_summary = false
	_show_leaderboard()
	_open()


func _open() -> void:
	var scene_music := get_tree().current_scene.get_node_or_null("BackgroundMusic") as AudioStreamPlayer
	if scene_music != null and scene_music != background_music:
		paused_background_music = scene_music
		paused_background_music.stream_paused = true
	play_music()
	visible = true
	get_tree().paused = true
	continue_button.grab_focus()


func _show_summary() -> void:
	title_label.text = "HÀNH TRÌNH HOÀN TẤT"
	summary_label.visible = true
	leaderboard_label.visible = false
	leaderboard_button.visible = true
	leaderboard_button.text = "Bảng xếp hạng"
	continue_button.text = "Tiếp tục khám phá"
	menu_button.visible = true


func _show_leaderboard() -> void:
	title_label.text = "BẢNG XẾP HẠNG CÁ NHÂN"
	summary_label.visible = false
	leaderboard_label.visible = true
	leaderboard_label.text = _build_leaderboard_text()
	leaderboard_button.visible = has_summary
	leaderboard_button.text = "Quay lại"
	continue_button.text = "Đóng" if not has_summary else "Tiếp tục khám phá"
	menu_button.visible = has_summary


func _build_leaderboard_text() -> String:
	var entries := SaveManager.get_leaderboard()
	if entries.is_empty():
		return "[center][font_size=22]Chưa có lượt hoàn thành nào.[/font_size][/center]"
	var lines := PackedStringArray([
		"[font_size=16][table=7]",
		"[cell=1 padding=6,6,6,8][center][b]Hạng[/b][/center][/cell]",
		"[cell=2 padding=6,6,6,8][center][b]Ngày[/b][/center][/cell]",
		"[cell=2 padding=6,6,6,8][center][b]Thời gian[/b][/center][/cell]",
		"[cell=1 padding=6,6,6,8][center][b]Energy[/b][/center][/cell]",
		"[cell=1 padding=6,6,6,8][center][b]Quái[/b][/center][/cell]",
		"[cell=1 padding=6,6,6,8][center][b]Bị hạ[/b][/center][/cell]",
		"[cell=1 padding=6,6,6,8][center][b]Nâng cấp[/b][/center][/cell]",
	])
	for index in entries.size():
		var entry := entries[index] as Dictionary
		var completed_at := str(entry.get("completed_at", ""))
		lines.append(
			("[cell=1 padding=6,5,6,5][center]%d[/center][/cell]"
			+ "[cell=2 padding=6,5,6,5][center]%s[/center][/cell]"
			+ "[cell=2 padding=6,5,6,5][center]%s[/center][/cell]"
			+ "[cell=1 padding=6,5,6,5][center]%d[/center][/cell]"
			+ "[cell=1 padding=6,5,6,5][center]%d[/center][/cell]"
			+ "[cell=1 padding=6,5,6,5][center]%d[/center][/cell]"
			+ "[cell=1 padding=6,5,6,5][center]%d[/center][/cell]") % [
				index + 1,
				completed_at.left(10),
				_format_time(int(entry.get("elapsed_seconds", 0))),
				int(entry.get("total_energy", 0)),
				int(entry.get("enemies_defeated", 0)),
				int(entry.get("deaths", 0)),
				int(entry.get("upgrades", 0)),
			]
		)
	lines.append("[/table][/font_size]")
	return "".join(lines)


func _format_time(seconds: int) -> String:
	return "%02d:%02d:%02d" % [seconds / 3600, seconds / 60 % 60, seconds % 60]


func _on_leaderboard_button_pressed() -> void:
	if leaderboard_label.visible:
		_show_summary()
	else:
		_show_leaderboard()


func _on_continue_button_pressed() -> void:
	_close()


func _on_menu_button_pressed() -> void:
	_close()
	SceneLoader.change_scene(MAIN_MENU_SCENE)


func _close() -> void:
	visible = false
	get_tree().paused = false
	if is_instance_valid(paused_background_music):
		background_music.stop()
		paused_background_music.stream_paused = false
		paused_background_music = null


func _exit_tree() -> void:
	if visible and get_tree() != null:
		get_tree().paused = false
