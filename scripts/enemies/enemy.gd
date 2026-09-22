extends CharacterBody2D

@export var health: int = 5
@export var speed: float = 100.0

@export var attack_damage: int = 1
@export var attack_range: float = 100.0
@export var attack_cooldown: float = 1.0

@export var knockback_force: float = 260.0
@export var knockback_duration: float = 0.12

@export var idle_animation: StringName = &"Idle"
@export var move_animation: StringName = &"Move"
@export var attack_animation: StringName = &"Attack"
@export var death_animation: StringName = &"death"

@export var hit_flash_duration: float = 0.16

@export var flip_sprite_to_direction: bool = true

@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
@onready var detection_area: Area2D = get_area_node("EnemyDetectionArea", "detection_area")
@onready var attack_hitbox: Area2D = get_area_node("EnemyAttackHitbox", "enemy_hitbox")
@onready var hurtbox: Area2D = get_area_node("EnemyHurtbox", "Hurtbox")
@onready var slash_effect: AnimatedSprite2D = get_node_or_null("slash_effect")

var player: CharacterBody2D
var has_detected_player: bool = false
var can_attack_player: bool = false
var attack_cooldown_left: float = 0.0
var is_playing_attack_animation: bool = false
var is_dead: bool = false

var is_knocked_back: bool = false
var knockback_time_left: float = 0.0
var knockback_direction: Vector2 = Vector2.ZERO
var hit_flash_tween: Tween


func _ready() -> void:
	add_to_group("enemy")

	player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	play_animation(idle_animation)

	if hurtbox != null:
		hurtbox.add_to_group("enemy_hurtbox")

	if animated_sprite != null:
		animated_sprite.animation_finished.connect(_on_animated_sprite_animation_finished)

	if slash_effect != null:
		slash_effect.visible = false
		slash_effect.stop()
		slash_effect.animation_finished.connect(_on_slash_effect_animation_finished)

	if detection_area != null:
		detection_area.body_entered.connect(_on_detection_area_body_entered)
		detection_area.body_exited.connect(_on_detection_area_body_exited)

	if attack_hitbox != null:
		attack_hitbox.area_entered.connect(_on_attack_hitbox_area_entered)
		attack_hitbox.area_exited.connect(_on_attack_hitbox_area_exited)
		attack_hitbox.body_entered.connect(_on_attack_hitbox_body_entered)
		attack_hitbox.body_exited.connect(_on_attack_hitbox_body_exited)


func _physics_process(delta: float) -> void:
	if is_dead:
		stop_moving()
		return

	if player == null:
		return

	if not is_instance_valid(player):
		return

	update_knockback(delta)
	if is_knocked_back:
		velocity = knockback_direction * knockback_force
		move_and_slide()
		return

	if attack_cooldown_left > 0.0:
		attack_cooldown_left -= delta

	update_detection_state()
	update_attack_hitbox_state()

	if not has_detected_player:
		stop_moving()
		play_animation(idle_animation)
		return

	var direction := global_position.direction_to(player.global_position)
	update_sprite_direction(direction)

	if can_attack_player:
		stop_moving()

		if attack_cooldown_left <= 0.0:
			attack_player()
		else:
			play_animation(idle_animation)

		return

	chase_player(direction)


func get_area_node(primary_name: String, fallback_name: String) -> Area2D:
	var node := get_node_or_null(primary_name) as Area2D
	if node != null:
		return node

	return get_node_or_null(fallback_name) as Area2D


func chase_player(direction: Vector2) -> void:
	velocity = direction * speed
	play_animation(move_animation)
	move_and_slide()


func stop_moving() -> void:
	velocity = Vector2.ZERO


func attack_player() -> void:
	if is_dead:
		return

	if player == null:
		return

	if not is_instance_valid(player):
		return

	player.take_damage(attack_damage, global_position)
	play_attack_animation()
	attack_cooldown_left = attack_cooldown


func take_damage(damage: int, attacker_position: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return

	health -= damage

	print("Enemy HP: ", health)

	play_hit_feedback()

	if health <= 0:
		die()
		return

	apply_knockback(attacker_position)


func play_hit_feedback() -> void:
	play_hit_flash()
	play_slash_effect()


func play_hit_flash() -> void:
	if animated_sprite == null:
		return

	if hit_flash_tween != null and hit_flash_tween.is_valid():
		hit_flash_tween.kill()

	animated_sprite.modulate = Color.WHITE
	hit_flash_tween = create_tween()
	hit_flash_tween.tween_property(animated_sprite, "modulate", Color(1.0, 0.25, 0.25, 0.45), hit_flash_duration * 0.25)
	hit_flash_tween.tween_property(animated_sprite, "modulate", Color.WHITE, hit_flash_duration * 0.25)
	hit_flash_tween.tween_property(animated_sprite, "modulate", Color(1.0, 0.25, 0.25, 0.45), hit_flash_duration * 0.25)
	hit_flash_tween.tween_property(animated_sprite, "modulate", Color.WHITE, hit_flash_duration * 0.25)

func play_slash_effect() -> void:
	if slash_effect == null:
		return

	if slash_effect.sprite_frames == null:
		return

	var animation_name := slash_effect.animation
	if animation_name == &"":
		animation_name = &"default"

	if not slash_effect.sprite_frames.has_animation(animation_name):
		return

	slash_effect.visible = true
	slash_effect.stop()
	slash_effect.frame = 0
	slash_effect.play(animation_name)

func die() -> void:
	if is_dead:
		return

	is_dead = true
	health = 0
	has_detected_player = false
	can_attack_player = false
	is_playing_attack_animation = false
	is_knocked_back = false
	stop_moving()
	disable_combat_areas()

	print("Enemy died")

	if animated_sprite == null:
		queue_free()
		return

	if animated_sprite.sprite_frames == null:
		queue_free()
		return

	if not animated_sprite.sprite_frames.has_animation(death_animation):
		queue_free()
		return

	animated_sprite.play(death_animation)


func disable_combat_areas() -> void:
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)

	set_area_enabled(detection_area, false)
	set_area_enabled(attack_hitbox, false)
	set_area_enabled(hurtbox, false)


func set_area_enabled(area: Area2D, is_enabled: bool) -> void:
	if area == null:
		return

	area.set_deferred("monitoring", is_enabled)
	area.set_deferred("monitorable", is_enabled)
	area.set_deferred("collision_layer", 0 if not is_enabled else area.collision_layer)
	area.set_deferred("collision_mask", 0 if not is_enabled else area.collision_mask)

func apply_knockback(attacker_position: Vector2) -> void:
	if attacker_position == Vector2.ZERO:
		return

	knockback_direction = attacker_position.direction_to(global_position)
	is_knocked_back = true
	knockback_time_left = knockback_duration


func update_knockback(delta: float) -> void:
	if not is_knocked_back:
		return

	knockback_time_left -= delta

	if knockback_time_left <= 0.0:
		is_knocked_back = false


func update_detection_state() -> void:
	if detection_area == null:
		has_detected_player = true
		return

	has_detected_player = false

	for body in detection_area.get_overlapping_bodies():
		if body.is_in_group("player"):
			player = body as CharacterBody2D
			has_detected_player = true
			return


func update_attack_hitbox_state() -> void:
	if attack_hitbox == null:
		can_attack_player = global_position.distance_to(player.global_position) <= attack_range
		return

	can_attack_player = false

	for area in attack_hitbox.get_overlapping_areas():
		if area.is_in_group("player_hurtbox"):
			player = area.get_parent() as CharacterBody2D
			can_attack_player = player != null
			return

	for body in attack_hitbox.get_overlapping_bodies():
		if body.is_in_group("player"):
			player = body as CharacterBody2D
			can_attack_player = true
			return


func update_sprite_direction(direction: Vector2) -> void:
	if not flip_sprite_to_direction:
		return

	if animated_sprite == null:
		return

	if absf(direction.x) <= 0.01:
		return

	animated_sprite.flip_h = direction.x < 0.0


func play_attack_animation() -> void:
	var animation_name := get_existing_animation(attack_animation, &"Attack_Start")

	if animation_name == &"":
		return

	play_animation(animation_name, true)

	if animated_sprite != null and animated_sprite.sprite_frames != null:
		is_playing_attack_animation = not animated_sprite.sprite_frames.get_animation_loop(animation_name)


func play_animation(animation_name: StringName, force_restart: bool = false) -> void:
	if is_dead:
		return

	if is_playing_attack_animation and not force_restart:
		return

	if animated_sprite == null:
		return

	if animated_sprite.sprite_frames == null:
		return

	if not animated_sprite.sprite_frames.has_animation(animation_name):
		return

	if force_restart:
		animated_sprite.play(animation_name)
		return

	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)
	elif not animated_sprite.is_playing():
		animated_sprite.play()


func get_existing_animation(preferred_animation: StringName, fallback_animation: StringName = &"") -> StringName:
	if animated_sprite == null:
		return &""

	if animated_sprite.sprite_frames == null:
		return &""

	if animated_sprite.sprite_frames.has_animation(preferred_animation):
		return preferred_animation

	if fallback_animation != &"" and animated_sprite.sprite_frames.has_animation(fallback_animation):
		return fallback_animation

	return &""


func _on_detection_area_body_entered(body: Node2D) -> void:
	if is_dead:
		return

	if not body.is_in_group("player"):
		return

	player = body as CharacterBody2D
	has_detected_player = true


func _on_detection_area_body_exited(body: Node2D) -> void:
	if is_dead:
		return

	if body != player:
		return

	has_detected_player = false
	can_attack_player = false
	stop_moving()
	play_animation(idle_animation)


func _on_attack_hitbox_area_entered(area: Area2D) -> void:
	if is_dead:
		return

	if not area.is_in_group("player_hurtbox"):
		return

	player = area.get_parent() as CharacterBody2D
	can_attack_player = player != null


func _on_attack_hitbox_area_exited(area: Area2D) -> void:
	if is_dead:
		return

	if not area.is_in_group("player_hurtbox"):
		return

	if area.get_parent() != player:
		return

	can_attack_player = false


func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	if is_dead:
		return

	if not body.is_in_group("player"):
		return

	player = body as CharacterBody2D
	can_attack_player = true


func _on_attack_hitbox_body_exited(body: Node2D) -> void:
	if is_dead:
		return

	if body != player:
		return

	can_attack_player = false


func _on_animated_sprite_animation_finished() -> void:
	if is_dead:
		queue_free()
		return

	is_playing_attack_animation = false


func _on_slash_effect_animation_finished() -> void:
	if slash_effect == null:
		return

	slash_effect.visible = false
	slash_effect.stop()
