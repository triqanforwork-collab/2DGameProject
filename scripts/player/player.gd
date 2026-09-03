extends CharacterBody2D

@export var speed: float = 220.0

@export var max_health: int = 5
@export var attack_damage: int = 1

@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.6

@export var invincibility_duration: float = 0.5

@export var knockback_force: float = 350.0
@export var knockback_duration: float = 0.15

@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

var health: int

var facing_direction: Vector2 = Vector2.RIGHT
var facing_animation_direction_name: String = "down"

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
	update_player_animation(Vector2.ZERO)


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	if direction != Vector2.ZERO:
		facing_direction = direction.normalized()
		update_attack_area()

	update_dash(delta)
	update_invincibility(delta)
	update_knockback(delta)

	if Input.is_action_just_pressed("dash"):
		start_dash()

	if is_knocked_back:
		velocity = knockback_direction * knockback_force

	elif is_dashing:
		velocity = facing_direction * dash_speed

	else:
		velocity = direction * speed

	move_and_slide()
	update_player_animation(facing_direction if is_dashing else direction, is_dashing)

	if Input.is_action_just_pressed("attack"):
		attack()


func update_attack_area() -> void:
	$AttackArea.position = facing_direction * 50.0


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
	var targets = $AttackArea.get_overlapping_bodies()

	for target in targets:
		if target.is_in_group("enemy"):
			target.take_damage(attack_damage)


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
