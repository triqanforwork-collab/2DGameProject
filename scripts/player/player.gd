extends CharacterBody2D

signal health_changed(current_health: int, maximum_health: int)
signal mana_changed(current_mana: int, maximum_mana: int)

const MAIN_AREA_SCENE_PATH := "res://scenes/maps/main.tscn"
const DEATH_DIALOG_MESSAGE := "Bạn muốn tiếp tục chiến đấu hay quay về đảo hồi sinh?"
const CONTINUE_BUTTON_TEXT := "Tiếp tục chiến đấu"
const RETURN_BUTTON_TEXT := "Quay về đảo hồi sinh"

@export var speed: float = 220.0

@export var max_health: int = 100
@export var max_mana: int = 100
@export var heal_amount: int = 10
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
@onready var heal_effect_sprite: AnimatedSprite2D = get_node_or_null("HealEffect")

var health: int
var mana: int

var facing_direction: Vector2 = Vector2.DOWN
var facing_animation_direction_name: String = "down"

var is_attacking: bool = false
var is_casting: bool = false
var is_dead: bool = false

var is_dashing: bool = false
var dash_time_left: float = 0.0
var dash_cooldown_left: float = 0.0

var is_invincible: bool = false
var invincibility_time_left: float = 0.0

var is_knocked_back: bool = false
var knockback_time_left: float = 0.0
var knockback_direction: Vector2 = Vector2.ZERO

var nearby_interactables: Array[Node] = []


func _ready() -> void:
	add_to_group("player")
	health = max_health
	mana = max_mana
	update_health_bar()
	update_mana_bar()
	update_attack_area()
	update_player_animation(Vector2.ZERO)

	if hurtbox != null:
		hurtbox.add_to_group("player_hurtbox")

	if animated_sprite != null:
		animated_sprite.animation_finished.connect(_on_animated_sprite_animation_finished)

	if heal_effect_sprite != null:
		heal_effect_sprite.visible = false
		heal_effect_sprite.animation_finished.connect(_on_heal_effect_animation_finished)


func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		return

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
		if not try_interact():
			attack()

	if Input.is_action_just_pressed("heal"):
		heal()

	if is_knocked_back:
		velocity = knockback_direction * knockback_force

	elif is_dashing:
		velocity = facing_direction * dash_speed

	else:
		velocity = direction * speed

	move_and_slide()

	if not is_attacking and not is_casting:
		update_player_animation(facing_direction if is_dashing else direction, is_dashing)


func get_hitbox_node(primary_name: String, fallback_name: String) -> Area2D:
	var node := get_node_or_null(primary_name) as Area2D
	if node != null:
		return node

	return get_node_or_null(fallback_name) as Area2D


func register_interactable(interactable: Node) -> void:
	if interactable not in nearby_interactables:
		nearby_interactables.append(interactable)


func unregister_interactable(interactable: Node) -> void:
	nearby_interactables.erase(interactable)


func try_interact() -> bool:
	var closest_interactable: Node2D = null
	var closest_distance := INF

	for interactable in nearby_interactables.duplicate():
		if not is_instance_valid(interactable):
			nearby_interactables.erase(interactable)
			continue

		if not interactable is Node2D:
			continue

		var distance := global_position.distance_squared_to(interactable.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_interactable = interactable

	if closest_interactable == null:
		return false

	if not closest_interactable.has_method("interact"):
		return false

	closest_interactable.interact(self)
	return true

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
	if is_attacking or is_casting:
		return

	if not play_attack_animation():
		return

	is_attacking = true
	apply_attack_damage()


func heal() -> void:
	if is_attacking or is_casting:
		return

	if health >= max_health:
		return

	health = min(health + heal_amount, max_health)
	update_health_bar()
	print("Player HP: ", health)
	play_castspell_animation()


func play_castspell_animation() -> void:
	if animated_sprite == null:
		return

	if animated_sprite.sprite_frames == null:
		return

	if not animated_sprite.sprite_frames.has_animation("castspell"):
		return

	is_casting = true
	animated_sprite.play("castspell")
	play_heal_effect_animation()


func play_heal_effect_animation() -> void:
	if heal_effect_sprite == null:
		return

	if heal_effect_sprite.sprite_frames == null:
		return

	if not heal_effect_sprite.sprite_frames.has_animation("heal_effect"):
		return

	heal_effect_sprite.visible = true
	heal_effect_sprite.play("heal_effect")


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
	if is_casting:
		return

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


func update_health_bar() -> void:
	health_changed.emit(health, max_health)


func update_mana_bar() -> void:
	mana_changed.emit(mana, max_mana)


func use_mana(amount: int) -> bool:
	var mana_cost := maxi(amount, 0)
	if mana < mana_cost:
		return false

	mana -= mana_cost
	update_mana_bar()
	return true


func restore_mana(amount: int) -> void:
	if amount <= 0 or mana >= max_mana:
		return

	mana = mini(mana + amount, max_mana)
	update_mana_bar()


func take_damage(damage: int, attacker_position: Vector2) -> void:
	if is_dead or is_invincible:
		return

	health -= damage
	update_health_bar()
	print("Player HP: ", health)

	if health <= 0:
		die()
		return

	is_invincible = true
	invincibility_time_left = invincibility_duration



func die() -> void:
	if is_dead:
		return

	is_dead = true
	health = 0
	velocity = Vector2.ZERO
	is_attacking = false
	is_casting = false
	is_dashing = false
	is_knocked_back = false
	nearby_interactables.clear()
	update_health_bar()
	print("Player died")

	var dialog := get_tree().get_first_node_in_group("confirmation_dialog")
	if dialog == null:
		push_error("Player death could not find the shared confirmation dialog.")
		SceneLoader.change_scene(MAIN_AREA_SCENE_PATH)
		return

	var callback := Callable(self, "_on_death_dialog_choice_made")
	dialog.connect("choice_made", callback, CONNECT_ONE_SHOT)
	var opened := bool(dialog.call(
		"open_dialog",
		DEATH_DIALOG_MESSAGE,
		CONTINUE_BUTTON_TEXT,
		RETURN_BUTTON_TEXT,
		false
	))
	if not opened:
		if dialog.is_connected("choice_made", callback):
			dialog.disconnect("choice_made", callback)
		SceneLoader.change_scene(MAIN_AREA_SCENE_PATH)


func _on_death_dialog_choice_made(continue_fighting: bool) -> void:
	if not continue_fighting:
		SceneLoader.change_scene(MAIN_AREA_SCENE_PATH)
		return

	var respawn_point := get_tree().get_first_node_in_group("region_respawn_point") as Node2D
	if respawn_point == null:
		push_error("Current Region does not have a respawn point.")
		SceneLoader.change_scene(MAIN_AREA_SCENE_PATH)
		return

	respawn_at(respawn_point.global_position)


func respawn_at(respawn_position: Vector2) -> void:
	global_position = respawn_position
	health = max_health
	mana = max_mana
	is_dead = false
	is_invincible = true
	invincibility_time_left = invincibility_duration
	dash_time_left = 0.0
	dash_cooldown_left = 0.0
	knockback_time_left = 0.0
	knockback_direction = Vector2.ZERO
	update_health_bar()
	update_mana_bar()
	update_attack_area()
	update_player_animation(Vector2.ZERO)

	if heal_effect_sprite != null:
		heal_effect_sprite.visible = false
		heal_effect_sprite.stop()


func _on_animated_sprite_animation_finished() -> void:
	if is_attacking:
		is_attacking = false
		update_player_animation(Vector2.ZERO)
		return

	if is_casting:
		is_casting = false
		update_player_animation(Vector2.ZERO)


func _on_heal_effect_animation_finished() -> void:
	if heal_effect_sprite == null:
		return

	heal_effect_sprite.visible = false
	heal_effect_sprite.stop()
