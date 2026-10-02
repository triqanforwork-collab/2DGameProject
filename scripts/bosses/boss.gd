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

var navigation_agent: NavigationAgent2D
var navigation_repath_time := 0.0
var navigation_stuck_time := 0.0
var last_navigation_position := Vector2.ZERO


func _ready() -> void:
	health = max_health
	super()
	add_to_group("boss")
	_setup_navigation_agent()

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


func _setup_navigation_agent() -> void:
	navigation_agent = NavigationAgent2D.new()
	navigation_agent.name = "NavigationAgent2D"
	navigation_agent.path_desired_distance = 10.0
	navigation_agent.target_desired_distance = 18.0
	navigation_agent.avoidance_enabled = false
	add_child(navigation_agent)
	last_navigation_position = global_position


func chase_player(_direction: Vector2) -> void:
	if navigation_agent == null or NavigationServer2D.map_get_iteration_id(navigation_agent.get_navigation_map()) == 0:
		super(global_position.direction_to(player.global_position))
		return

	var delta := get_physics_process_delta_time()
	navigation_repath_time -= delta
	if navigation_repath_time <= 0.0:
		navigation_agent.target_position = player.global_position
		navigation_repath_time = 0.2

	var next_position := navigation_agent.get_next_path_position()
	var direction := global_position.direction_to(next_position)
	if next_position == Vector2.ZERO:
		direction = global_position.direction_to(player.global_position)

	velocity = direction * speed
	play_animation(move_animation)
	move_and_slide()
	update_sprite_direction(direction)

	if global_position.distance_to(last_navigation_position) < 2.0:
		navigation_stuck_time += delta
	else:
		navigation_stuck_time = 0.0
		last_navigation_position = global_position
	if navigation_stuck_time >= 0.5:
		navigation_agent.target_position = player.global_position
		navigation_stuck_time = 0.0


func update_attack_hitbox_state() -> void:
	super()
	if can_attack_player and not _has_line_of_sight_to_player():
		can_attack_player = false


func _has_line_of_sight_to_player() -> bool:
	if not is_instance_valid(player):
		return false
	var query := PhysicsRayQueryParameters2D.create(global_position, player.global_position, 1)
	query.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()


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
