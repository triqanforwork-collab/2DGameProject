extends Area2D

const EXPLOSION_SCENE: PackedScene = preload("res://scenes/player/PlayerAreaAttackExplosion.tscn")

@export var speed: float = 420.0
@export var max_distance: float = 520.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var direction := Vector2.RIGHT
var damage := 1
var traveled_distance := 0.0
var hit_resolved := false
var target: Node2D


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	animated_sprite.play(&"travel")


func setup(
	start_position: Vector2,
	travel_direction: Vector2,
	attack_damage: int,
	projectile_speed: float,
	projectile_range: float
) -> void:
	global_position = start_position
	direction = travel_direction.normalized()
	damage = maxi(attack_damage, 1)
	speed = maxf(projectile_speed, 1.0)
	max_distance = maxf(projectile_range, 1.0)
	rotation = direction.angle()
	target = _find_nearest_target()


func _physics_process(delta: float) -> void:
	if hit_resolved:
		return
	if not is_instance_valid(target) or bool(target.get("is_dead")):
		target = _find_nearest_target()
	if target != null:
		direction = global_position.direction_to(target.global_position)
		rotation = direction.angle()

	var movement := direction * speed * delta
	global_position += movement
	traveled_distance += movement.length()

	if traveled_distance >= max_distance:
		queue_free()


func _find_nearest_target() -> Node2D:
	var nearest: Node2D
	var nearest_distance_squared := pow(maxf(max_distance - traveled_distance, 0.0), 2)
	for candidate in get_tree().get_nodes_in_group("enemy"):
		var enemy := candidate as Node2D
		if enemy == null or bool(enemy.get("is_dead")):
			continue

		var distance_squared := global_position.distance_squared_to(enemy.global_position)
		if distance_squared >= nearest_distance_squared or not _has_clear_path(enemy.global_position):
			continue

		nearest = enemy
		nearest_distance_squared = distance_squared

	return nearest


func _has_clear_path(target_position: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(global_position, target_position, 1)
	query.collide_with_areas = false
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _explode() -> void:
	if hit_resolved:
		return

	hit_resolved = true
	set_physics_process(false)
	set_deferred("monitoring", false)
	$CollisionShape2D.set_deferred("disabled", true)
	animated_sprite.visible = false
	_spawn_explosion.call_deferred()


func _spawn_explosion() -> void:
	var projectile_parent := get_parent()
	if projectile_parent != null:
		var explosion := EXPLOSION_SCENE.instantiate()
		projectile_parent.add_child(explosion)
		explosion.global_position = global_position
		explosion.call("setup", damage)

	queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_hurtbox"):
		_explode()


func _on_body_entered(_body: Node2D) -> void:
	_explode()
