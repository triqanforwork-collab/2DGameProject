class_name BossWarningOverlay
extends CanvasLayer

@onready var overlay: Control = $Overlay
@onready var warning_label: Label = $Overlay/Center/Content/WarningLabel
@onready var boss_label: Label = $Overlay/Center/Content/BossLabel
@onready var subtitle_label: Label = $Overlay/Center/Content/SubtitleLabel
@onready var backdrop: ColorRect = $Overlay/Backdrop
@onready var top_line: ColorRect = $Overlay/TopLine
@onready var bottom_line: ColorRect = $Overlay/BottomLine

var pulse_tween: Tween


func _ready() -> void:
	visible = false


func play_warning(boss_name: String, hold_duration: float) -> void:
	warning_label.text = "CẢNH BÁO"
	boss_label.text = boss_name
	subtitle_label.text = "Một nguồn năng lượng mạnh đang xuất hiện"
	warning_label.add_theme_color_override("font_color", Color(1, 0.18, 0.12))
	backdrop.color = Color(0.12, 0.005, 0.015, 0.72)
	top_line.color = Color(0.95, 0.12, 0.08, 0.9)
	bottom_line.color = top_line.color
	await _play(hold_duration)


func play_celebration(stone_name: String, reward_text: String, hold_duration: float = 3.0) -> void:
	warning_label.text = "CHÚC MỪNG!"
	boss_label.text = "%s ĐÃ THỨC TỈNH" % stone_name.to_upper()
	subtitle_label.text = reward_text
	warning_label.add_theme_color_override("font_color", Color(1, 0.84, 0.25))
	backdrop.color = Color(0.015, 0.08, 0.055, 0.78)
	top_line.color = Color(0.35, 1.0, 0.58, 0.95)
	bottom_line.color = top_line.color
	await _play(hold_duration)


func _play(hold_duration: float) -> void:
	if pulse_tween != null and pulse_tween.is_valid():
		pulse_tween.kill()

	overlay.modulate = Color(1, 1, 1, 0)
	warning_label.modulate = Color(1, 1, 1, 0)
	boss_label.modulate = Color(1, 1, 1, 0)
	subtitle_label.modulate = Color(1, 1, 1, 0)
	visible = true

	var intro := create_tween()
	intro.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	intro.set_parallel(true)
	intro.tween_property(overlay, "modulate:a", 1.0, 0.25)
	intro.tween_property(warning_label, "modulate:a", 1.0, 0.18)
	intro.tween_property(boss_label, "modulate:a", 1.0, 0.32).set_delay(0.18)
	intro.tween_property(subtitle_label, "modulate:a", 1.0, 0.32).set_delay(0.32)
	await intro.finished

	pulse_tween = create_tween()
	pulse_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	pulse_tween.set_loops()
	pulse_tween.tween_property(warning_label, "modulate:a", 0.35, 0.22)
	pulse_tween.tween_property(warning_label, "modulate:a", 1.0, 0.22)

	await get_tree().create_timer(maxf(hold_duration, 0.1)).timeout

	if pulse_tween != null and pulse_tween.is_valid():
		pulse_tween.kill()

	var outro := create_tween()
	outro.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	outro.tween_property(overlay, "modulate:a", 0.0, 0.22)
	await outro.finished
	visible = false
