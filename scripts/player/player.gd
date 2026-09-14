extends CharacterBody2D

@export var speed: float = 220.0

@export var max_health: int = 100
@export var attack_damage: int = 1

@export var dash_speed: float = 1000.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.6

@export var invincibility_duration: float = 0.5

@export var knockback_force: float = 350.0
@export var knockback_duration: float = 0.15

@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
@onready var attack_hitbox: Area2D = get_hitbox_node("PlayerAttackHitbox", "AttackArea")
@onready var hurtbox: Area2D = get_hitbox_node("PlayerHurtbox", "Hurtbox")

var health: int

var facing_direction: Vector2 = Vector2.DOWN
var facing_animation_direction_name: String = "down"

var is_attacking: bool = false

var is_dashing: bool = false
var dash_time_left: float = 0.0
var dash_cooldown_left: float = 0.0

var is_invincible: bool = false
var invincibility_time_left: float = 0.0

var is_knocked_back: bool = false
var knockback_time_left: float = 0.0
var knockback_direction: Vector2 = Vector2.ZERO


func _ready() -> void:
	add_to_group("player")
	health = max_health
	update_attack_area()
	update_player_animation(Vector2.ZERO)

	if hurtbox != null:
		hurtbox.add_to_group("player_hurtbox")

	if animated_sprite != null:
		animated_sprite.animation_finished.connect(_on_animated_sprite_animation_finished)


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	if direction != Vector2.ZERO:
		facing_direction = direction.normalized()
		facing_animation_direction_name = get_cardinal_animation_direction(facing_direction)
		update_attack_area()

	update_dash(delta)
	update_invincibility(delta)
	update_knockback(delta)

	if Input.is_action_just_pressed("dash"):
		start_dash()

	if Input.is_action_just_pressed("attack"):
		attack()

	if is_knocked_back:
		velocity = knockback_direction * knockback_force

	elif is_dashing:
		velocity = facing_direction * dash_speed

	else:
		velocity = direction * speed

	move_and_slide()

	if not is_attacking:
		update_player_animation(facing_direction if is_dashing else direction, is_dashing)


func get_hitbox_node(primary_name: String, fallback_name: String) -> Area2D:
	var node := get_node_or_null(primary_name) as Area2D
	if node != null:
		return node

	return get_node_or_null(fallback_name) as Area2D


func update_attack_area() -> void:
	if attack_hitbox == null:
		return

	attack_hitbox.position = facing_direction * 50.0


func update_player_animation(move_direction: Vector2, use_run_animation: bool = false) -> void:
	if animated_sprite == null:
		return

	if animated_sprite.sprite_frames == null:
		return

	var animation_prefix := "idle"
	if move_direction != Vector2.ZERO:
		facing_animation_direction_name = get_cardinal_animation_direction(move_direction.normalized())
		animation_prefix = "run" if use_run_animation else "walk"

	var animation_name := "%s_%s" % [animation_prefix, facing_animation_direction_name]
	if not animated_sprite.sprite_frames.has_animation(animation_name):
		return

	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)
	elif not animated_sprite.is_playing():
		animated_sprite.play()


func get_cardinal_animation_direction(direction: Vector2) -> String:
	if absf(direction.x) > absf(direction.y):
		return "right" if direction.x > 0.0 else "left"

	return "down" if direction.y > 0.0 else "up"


func attack() -> void:
	if is_attacking:
		return

	if not play_attack_animation():
		return

	is_attacking = true
	apply_attack_damage()


func apply_attack_damage() -> void:
	if attack_hitbox == null:
		return

	var damaged_enemies: Array[Node] = []

	for area in attack_hitbox.get_overlapping_areas():
		if not area.is_in_group("enemy_hurtbox"):
			continue

		var enemy := area.get_parent()
		if enemy == null:
			continue

		if enemy in damaged_enemies:
			continue

		if enemy.has_method("take_damage"):
			enemy.take_damage(attack_damage, global_position)
			damaged_enemies.append(enemy)

	for body in attack_hitbox.get_overlapping_bodies():
		if not body.is_in_group("enemy"):
			continue

		if body in damaged_enemies:
			continue

		if body.has_method("take_damage"):
			body.take_damage(attack_damage, global_position)
			damaged_enemies.append(body)


func play_attack_animation() -> bool:
	if animated_sprite == null:
		return false

	if animated_sprite.sprite_frames == null:
		return false

	var animation_name := "%s_attack" % facing_animation_direction_name
	if not animated_sprite.sprite_frames.has_animation(animation_name):
		return false

	animated_sprite.play(animation_name)
	return true


func start_dash() -> void:
	if dash_cooldown_left > 0.0:
		return

	if is_knocked_back:
		return

	is_dashing = true
	dash_time_left = dash_duration
	dash_cooldown_left = dash_cooldown


func update_dash(delta: float) -> void:
	if dash_cooldown_left > 0.0:
		dash_cooldown_left -= delta

	if is_dashing:
		dash_time_left -= delta

		if dash_time_left <= 0.0:
			is_dashing = false


func update_invincibility(delta: float) -> void:
	if not is_invincible:
		return

	invincibility_time_left -= delta

	if invincibility_time_left <= 0.0:
		is_invincible = false


func update_knockback(delta: float) -> void:
	if not is_knocked_back:
		return

	knockback_time_left -= delta

	if knockback_time_left <= 0.0:
		is_knocked_back = false


func take_damage(damage: int, attacker_position: Vector2) -> void:
	if is_invincible:
		return

	health -= damage
	print("Player HP: ", health)

	if health <= 0:
		die()
		return

	is_invincible = true
	invincibility_time_left = invincibility_duration

	knockback_direction = attacker_position.direction_to(global_position)
	is_knocked_back = true
	knockback_time_left = knockback_duration


func die() -> void:
	print("Player died")
	queue_free()


func _on_animated_sprite_animation_finished() -> void:
	if not is_attacking:
		return

	is_attacking = false
	update_player_animation(Vector2.ZERO)
