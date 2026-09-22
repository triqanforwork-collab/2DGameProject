extends CanvasLayer

@onready var health_bar: TextureProgressBar = $ScreenAnchor/HUDPanel/InnerMargin/Content/HealthSection/HealthBar/Fill
@onready var health_value: Label = $ScreenAnchor/HUDPanel/InnerMargin/Content/HealthSection/HealthBar/HealthValue
@onready var mana_bar: TextureProgressBar = $ScreenAnchor/HUDPanel/InnerMargin/Content/HealthSection/ManaBar/Fill
@onready var mana_value: Label = $ScreenAnchor/HUDPanel/InnerMargin/Content/HealthSection/ManaBar/ManaValue

var player: Node


func _ready() -> void:
	player = get_parent()
	if player == null:
		return

	if player.has_signal("health_changed"):
		player.connect("health_changed", _on_health_changed)
	if player.has_signal("mana_changed"):
		player.connect("mana_changed", _on_mana_changed)

	_sync_from_player.call_deferred()


func _sync_from_player() -> void:
	if not is_instance_valid(player):
		return

	_on_health_changed(int(player.get("health")), int(player.get("max_health")))
	_on_mana_changed(int(player.get("mana")), int(player.get("max_mana")))


func _on_health_changed(current_health: int, maximum_health: int) -> void:
	var safe_maximum := maxi(maximum_health, 1)
	var display_health := clampi(current_health, 0, safe_maximum)
	health_bar.max_value = safe_maximum
	health_bar.value = display_health
	health_value.text = "%d / %d" % [display_health, safe_maximum]


func _on_mana_changed(current_mana: int, maximum_mana: int) -> void:
	var safe_maximum := maxi(maximum_mana, 1)
	var display_mana := clampi(current_mana, 0, safe_maximum)
	mana_bar.max_value = safe_maximum
	mana_bar.value = display_mana
	mana_value.text = "%d / %d" % [display_mana, safe_maximum]
