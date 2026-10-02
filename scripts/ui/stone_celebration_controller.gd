extends Node

@onready var overlay: BossWarningOverlay = $BossWarningOverlay
@onready var fireworks: Control = $CelebrationLayer/VictoryFireworks
@onready var celebration_sound: AudioStreamPlayer = $CelebrationSound
@onready var final_summary: Control = $FinalSummaryLayer/FinalSummary


func _ready() -> void:
	ProgressionManager.stone_activated.connect(_on_stone_activated)
	if ProgressionManager.has_completed_game and not SaveManager.completion_recorded:
		_show_recovered_summary.call_deferred()


func _show_recovered_summary() -> void:
	final_summary.call("open_summary", SaveManager.complete_run())


func _on_stone_activated(stone_id: StringName, _reward_id: StringName) -> void:
	var data := ProgressionManager.get_stone_data(stone_id)
	celebration_sound.play()
	fireworks.play()
	await overlay.play_celebration(
		str(data.get("display_name", "Energy Stone")),
		str(data.get("reward_description", "Đã mở khóa phần thưởng"))
	)
	if stone_id == &"life":
		final_summary.call("open_summary", SaveManager.complete_run())
