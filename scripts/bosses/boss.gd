extends "res://scripts/enemies/enemy.gd"

signal defeated(boss: Node)

@export var boss_name: String = "Boss"
@export var max_health: int = 40
@export var boss_energy_drop := 30
@export_range(1, 10, 1) var energy_per_pickup := 5

@onready var boss_health_bar: Control = get_node_or_null("BossHealthUI/BossHealthBar")
@onready var health_background: ColorRect = get_node_or_null("BossHealthUI/BossHealthBar/Background")
@onready var health_fill: ColorRect = get_node_or_null("BossHealthUI/BossHealthBar/Fill")
@onready var boss_name_label: Label = get_node_or_null("BossHealthUI/BossHealthBar/BossName")


func _ready() -> void:
	health = max_health
	super()
	add_to_group("boss")

	if boss_name_label != null:
		boss_name_label.text = boss_name

	if boss_health_bar != null:
		boss_health_bar.visible = false

	if health_background != null:
		health_background.resized.connect(update_health_bar)

	update_health_bar.call_deferred()


func _physics_process(delta: float) -> void:
	super(delta)

	if boss_health_bar != null:
		boss_health_bar.visible = has_detected_player and not is_dead


func take_damage(damage: int, attacker_position: Vector2 = Vector2.ZERO) -> void:
	super(damage, attacker_position)
	update_health_bar()


func die() -> void:
	if is_dead:
		return

	if boss_health_bar != null:
		boss_health_bar.visible = false

	super()
	defeated.emit(self)


func get_energy_drop_amount() -> int:
	return boss_energy_drop


func get_energy_per_pickup() -> int:
	return energy_per_pickup


func configure_energy_pickup(pickup: Node) -> void:
	pickup.add_to_group("boss_energy_pickup")
	pickup.set("magnet_radius", 320.0)
	pickup.set("magnet_speed", 360.0)


func update_health_bar() -> void:
	if health_background == null or health_fill == null:
		return

	var health_ratio := clampf(float(health) / float(max_health), 0.0, 1.0)
	var horizontal_padding := health_fill.position.x * 2.0
	var available_width := maxf(health_background.size.x - horizontal_padding, 0.0)
	health_fill.size.x = available_width * health_ratio
