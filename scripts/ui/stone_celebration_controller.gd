extends Node

@onready var overlay: BossWarningOverlay = $BossWarningOverlay
@onready var fireworks: Control = $CelebrationLayer/VictoryFireworks
@onready var celebration_sound: AudioStreamPlayer = $CelebrationSound


func _ready() -> void:
	ProgressionManager.stone_activated.connect(_on_stone_activated)


func _on_stone_activated(stone_id: StringName, _reward_id: StringName) -> void:
	var data := ProgressionManager.get_stone_data(stone_id)
	celebration_sound.play()
	fireworks.play()
	await overlay.play_celebration(
		str(data.get("display_name", "Energy Stone")),
		str(data.get("reward_description", "Đã mở khóa phần thưởng"))
	)
