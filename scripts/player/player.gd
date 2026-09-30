extends CharacterBody2D

signal health_changed(current_health: int, maximum_health: int)
signal mana_changed(current_mana: int, maximum_mana: int)
signal interaction_availability_changed(available: bool)
signal weapon_mode_changed(mode: int)

enum WeaponMode {
	SWORD,
	STAFF,
}

const MAIN_AREA_SCENE_PATH := "res://scenes/maps/main.tscn"
const MAIN_MENU_SCENE_PATH := "res://scenes/ui/MainMenu.tscn"
const STAFF_SPRITE_FRAMES: SpriteFrames = preload("res://assets/characters/player_lpc/staff/staff_spriteframes.tres")
const MAGIC_BEAM_SCENE: PackedScene = preload("res://scenes/player/PlayerMagicBeam.tscn")
const AREA_ATTACK_PROJECTILE_SCENE: PackedScene = preload("res://scenes/player/PlayerAreaAttackProjectile.tscn")
const DEATH_DIALOG_MESSAGE := "Bạn muốn tiếp tục chiến đấu hay quay về đảo hồi sinh?"
const CONTINUE_BUTTON_TEXT := "Tiếp tục chiến đấu"
const RETURN_BUTTON_TEXT := "Quay về đảo hồi sinh"
const MAIN_MENU_BUTTON_TEXT := "Về Main Menu"

@export var speed: float = 220.0

@export var max_health: int = 100
@export var max_mana: int = 100
@export var attack_damage: int = 20
@export var mana_regen_per_second: float = 4.0
@export var mana_regen_delay: float = 2.0

@export_category("Abilities")
@export var heal_unlocked: bool = false
@export var heal_amount: int = 30
@export var heal_mana_cost: int = 25
@export var heal_cooldown: float = 5.0

@export_category("Area Attack")
@export var area_attack_unlocked: bool = false
@export var area_attack_mana_cost: int = 35
@export var area_attack_cooldown: float = 8.0
@export var area_attack_damage: int = 150
@export var area_attack_projectile_speed: float = 420.0
@export var area_attack_projectile_range: float = 520.0
@export var area_attack_spawn_distance: float = 38.0
@export var area_attack_windup: float = 0.22

@export_category("Staff")
@export var staff_unlocked: bool = false
@export var staff_attack_damage: int = 7
@export var staff_beam_range: float = 520.0
@export var staff_beam_spawn_distance: float = 38.0
@export var staff_beam_windup: float = 0.22

@export var dash_speed: float = 1000.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.6

@export var invincibility_duration: float = 0.5
@export var hit_flash_duration: float = 0.2
@export var death_effect_duration: float = 3.0
@export var death_blink_interval: float = 0.15

@export var knockback_force: float = 350.0
@export var knockback_duration: float = 0.15

@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
@onready var attack_hitbox: Area2D = get_hitbox_node("PlayerAttackHitbox", "AttackArea")
@onready var hurtbox: Area2D = get_hitbox_node("PlayerHurtbox", "Hurtbox")
@onready var heal_effect_sprite: AnimatedSprite2D = get_node_or_null("HealEffect")
@onready var death_sound: AudioStreamPlayer = get_node_or_null("DeathSound")

var health: int
var mana: int
var sword_sprite_frames: SpriteFrames
var weapon_mode: WeaponMode = WeaponMode.SWORD
var staff_attack_sequence := 0
var heal_cooldown_left := 0.0
var area_attack_cooldown_left := 0.0
var area_attack_cast_sequence := 0
var mana_regen_delay_left := 0.0
var mana_regen_buffer := 0.0

var base_max_health: int
var base_max_mana: int
var base_attack_damage: int
var base_staff_attack_damage: int
var base_heal_amount: int
var base_area_attack_damage: int

var facing_direction: Vector2 = Vector2.DOWN
var facing_animation_direction_name: String = "down"

var is_attacking: bool = false
var is_casting: bool = false
var is_dead: bool = false
var controls_locked: bool = false

var is_dashing: bool = false
var dash_time_left: float = 0.0
var dash_cooldown_left: float = 0.0

var is_invincible: bool = false
var invincibility_time_left: float = 0.0
var hit_flash_tween: Tween

var is_knocked_back: bool = false
var knockback_time_left: float = 0.0
var knockback_direction: Vector2 = Vector2.ZERO

var nearby_interactables: Array[Node] = []


func _ready() -> void:
	add_to_group("player")
	base_max_health = max_health
	base_max_mana = max_mana
	base_attack_damage = attack_damage
	base_staff_attack_damage = staff_attack_damage
	base_heal_amount = heal_amount
	base_area_attack_damage = area_attack_damage
	_apply_stat_upgrades(false)
	health = max_health
	mana = max_mana
	heal_unlocked = ProgressionManager.is_reward_unlocked(&"heal")
	staff_unlocked = ProgressionManager.is_reward_unlocked(&"staff")
	area_attack_unlocked = ProgressionManager.is_reward_unlocked(&"area_attack")
	if not ProgressionManager.reward_unlocked.is_connected(_on_progression_reward_unlocked):
		ProgressionManager.reward_unlocked.connect(_on_progression_reward_unlocked)
	if not ProgressionManager.stat_upgrade_changed.is_connected(_on_stat_upgrade_changed):
		ProgressionManager.stat_upgrade_changed.connect(_on_stat_upgrade_changed)
	update_health_bar()
	update_mana_bar()
	update_attack_area()
	update_player_animation(Vector2.ZERO)

	if hurtbox != null:
		hurtbox.add_to_group("player_hurtbox")

	if animated_sprite != null:
		sword_sprite_frames = animated_sprite.sprite_frames
		animated_sprite.animation_finished.connect(_on_animated_sprite_animation_finished)

	if heal_effect_sprite != null:
		heal_effect_sprite.visible = false
		heal_effect_sprite.animation_finished.connect(_on_heal_effect_animation_finished)


func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		return

	if controls_locked:
		velocity = Vector2.ZERO
		if not is_attacking and not is_casting:
			update_player_animation(Vector2.ZERO)
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
	update_heal_cooldown(delta)
	update_area_attack_cooldown(delta)
	update_mana_regeneration(delta)
	update_invincibility(delta)
	update_knockback(delta)

	if Input.is_action_just_pressed("dash"):
		start_dash()

	if Input.is_action_just_pressed("switch_weapon"):
		toggle_weapon()

	var interaction_triggered := false
	if Input.is_action_just_pressed("interact"):
		interaction_triggered = try_interact()

	if Input.is_action_just_pressed("attack") and not interaction_triggered:
		attack()

	if Input.is_action_just_pressed("heal"):
		heal()

	if Input.is_action_just_pressed("area_attack"):
		area_attack()

	if is_knocked_back:
		velocity = knockback_direction * knockback_force

	elif is_dashing:
		velocity = facing_direction * dash_speed

	else:
		velocity = direction * speed

	move_and_slide()

	if not is_attacking and not is_casting:
		update_player_animation(facing_direction if is_dashing else direction, is_dashing)


func set_cinematic_locked(locked: bool) -> void:
	controls_locked = locked
	if not locked:
		return

	velocity = Vector2.ZERO
	is_dashing = false
	dash_time_left = 0.0
	is_knocked_back = false
	knockback_time_left = 0.0
	if not is_attacking and not is_casting:
		update_player_animation(Vector2.ZERO)


func get_hitbox_node(primary_name: String, fallback_name: String) -> Area2D:
	var node := get_node_or_null(primary_name) as Area2D
	if node != null:
		return node

	return get_node_or_null(fallback_name) as Area2D


func register_interactable(interactable: Node) -> void:
	if interactable not in nearby_interactables:
		nearby_interactables.append(interactable)
		interaction_availability_changed.emit(true)


func unregister_interactable(interactable: Node) -> void:
	nearby_interactables.erase(interactable)
	interaction_availability_changed.emit(has_available_interactable())


func has_available_interactable() -> bool:
	for interactable in nearby_interactables.duplicate():
		if not is_instance_valid(interactable):
			nearby_interactables.erase(interactable)
			continue
		return true

	return false


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
	staff_attack_sequence += 1
	if weapon_mode == WeaponMode.STAFF:
		_fire_staff_beam_after_windup(staff_attack_sequence)
	else:
		apply_attack_damage()


func toggle_weapon() -> void:
	if is_dead or is_attacking or is_casting:
		return

	if animated_sprite == null:
		return

	if weapon_mode == WeaponMode.SWORD and not staff_unlocked:
		return

	weapon_mode = WeaponMode.STAFF if weapon_mode == WeaponMode.SWORD else WeaponMode.SWORD
	animated_sprite.stop()
	animated_sprite.sprite_frames = STAFF_SPRITE_FRAMES if weapon_mode == WeaponMode.STAFF else sword_sprite_frames
	update_player_animation(Vector2.ZERO)
	weapon_mode_changed.emit(int(weapon_mode))


func _fire_staff_beam_after_windup(attack_sequence: int) -> void:
	await get_tree().create_timer(maxf(staff_beam_windup, 0.0)).timeout
	if is_dead or not is_attacking:
		return
	if weapon_mode != WeaponMode.STAFF or attack_sequence != staff_attack_sequence:
		return

	var beam_parent := get_tree().current_scene
	if beam_parent == null:
		return

	var beam := MAGIC_BEAM_SCENE.instantiate()
	beam_parent.add_child(beam)
	beam.call(
		"setup",
		global_position + facing_direction * staff_beam_spawn_distance,
		facing_direction,
		staff_attack_damage,
		staff_beam_range
	)


func heal() -> void:
	if not heal_unlocked or heal_cooldown_left > 0.0:
		return

	if is_attacking or is_casting:
		return

	if health >= max_health:
		return

	if not use_mana(heal_mana_cost):
		return

	health = min(health + heal_amount, max_health)
	heal_cooldown_left = heal_cooldown
	update_health_bar()
	print("Player HP: ", health)
	play_castspell_animation()


func area_attack() -> void:
	if not area_attack_unlocked or area_attack_cooldown_left > 0.0:
		return

	if is_dead or is_attacking or is_casting:
		return

	if not use_mana(area_attack_mana_cost):
		return

	area_attack_cooldown_left = area_attack_cooldown
	area_attack_cast_sequence += 1
	play_castspell_animation(false)
	_fire_area_attack_after_windup(area_attack_cast_sequence)


func _fire_area_attack_after_windup(cast_sequence: int) -> void:
	await get_tree().create_timer(maxf(area_attack_windup, 0.0)).timeout
	if is_dead or cast_sequence != area_attack_cast_sequence:
		return

	var projectile_parent := get_tree().current_scene
	if projectile_parent == null:
		return

	var projectile := AREA_ATTACK_PROJECTILE_SCENE.instantiate()
	projectile_parent.add_child(projectile)
	projectile.call(
		"setup",
		global_position + facing_direction * area_attack_spawn_distance,
		facing_direction,
		area_attack_damage,
		area_attack_projectile_speed,
		area_attack_projectile_range
	)


func play_castspell_animation(show_heal_effect: bool = true) -> void:
	if animated_sprite == null:
		return

	if animated_sprite.sprite_frames == null:
		return

	if not animated_sprite.sprite_frames.has_animation("castspell"):
		return

	is_casting = true
	animated_sprite.play("castspell")
	if show_heal_effect:
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


func update_heal_cooldown(delta: float) -> void:
	if heal_cooldown_left > 0.0:
		heal_cooldown_left = maxf(heal_cooldown_left - delta, 0.0)


func update_area_attack_cooldown(delta: float) -> void:
	if area_attack_cooldown_left > 0.0:
		area_attack_cooldown_left = maxf(area_attack_cooldown_left - delta, 0.0)


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
	mana_regen_delay_left = mana_regen_delay
	mana_regen_buffer = 0.0
	update_mana_bar()
	return true


func update_mana_regeneration(delta: float) -> void:
	if mana >= max_mana:
		mana_regen_buffer = 0.0
		return
	if mana_regen_delay_left > 0.0:
		mana_regen_delay_left = maxf(mana_regen_delay_left - delta, 0.0)
		return

	mana_regen_buffer += mana_regen_per_second * delta
	var restored := int(floor(mana_regen_buffer))
	if restored > 0:
		mana_regen_buffer -= restored
		restore_mana(restored)


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

	play_hit_flash()
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
	interaction_availability_changed.emit(false)
	update_health_bar()
	print("Player died")

	if hit_flash_tween != null and hit_flash_tween.is_valid():
		hit_flash_tween.kill()
	if animated_sprite != null:
		animated_sprite.modulate = Color.WHITE

	if heal_effect_sprite != null:
		heal_effect_sprite.visible = false
		heal_effect_sprite.stop()

	if death_sound != null:
		death_sound.play()

	play_death_sequence()


func play_hit_flash() -> void:
	if animated_sprite == null:
		return

	if hit_flash_tween != null and hit_flash_tween.is_valid():
		hit_flash_tween.kill()

	animated_sprite.modulate = Color.WHITE
	hit_flash_tween = create_tween()
	hit_flash_tween.tween_property(animated_sprite, "modulate", Color(1.0, 0.2, 0.2, 0.35), hit_flash_duration * 0.25)
	hit_flash_tween.tween_property(animated_sprite, "modulate", Color.WHITE, hit_flash_duration * 0.25)
	hit_flash_tween.tween_property(animated_sprite, "modulate", Color(1.0, 0.2, 0.2, 0.35), hit_flash_duration * 0.25)
	hit_flash_tween.tween_property(animated_sprite, "modulate", Color.WHITE, hit_flash_duration * 0.25)


func play_death_sequence() -> void:
	var effect_duration := maxf(death_effect_duration, 0.0)
	var blink_interval := maxf(death_blink_interval, 0.05)
	var started_at := Time.get_ticks_msec()

	while true:
		var elapsed := float(Time.get_ticks_msec() - started_at) / 1000.0
		var remaining := effect_duration - elapsed
		if remaining <= 0.0:
			break

		if animated_sprite != null:
			animated_sprite.visible = not animated_sprite.visible

		await get_tree().create_timer(minf(blink_interval, remaining)).timeout

	if animated_sprite != null:
		animated_sprite.visible = true

	if is_dead:
		open_death_dialog()


func open_death_dialog() -> void:
	var dialog := get_tree().get_first_node_in_group("confirmation_dialog")
	if dialog == null:
		push_error("Player death could not find the shared confirmation dialog.")
		SceneLoader.change_scene(MAIN_AREA_SCENE_PATH)
		return

	var callback := Callable(self, "_on_death_dialog_option_selected")
	dialog.connect("option_selected", callback, CONNECT_ONE_SHOT)
	var opened := bool(dialog.call(
		"open_dialog",
		DEATH_DIALOG_MESSAGE,
		CONTINUE_BUTTON_TEXT,
		RETURN_BUTTON_TEXT,
		false,
		MAIN_MENU_BUTTON_TEXT
	))
	if not opened:
		if dialog.is_connected("option_selected", callback):
			dialog.disconnect("option_selected", callback)
		SceneLoader.change_scene(MAIN_AREA_SCENE_PATH)


func _on_death_dialog_option_selected(option_index: int) -> void:
	var destination := get_death_destination(option_index)
	if not destination.is_empty():
		SceneLoader.change_scene(destination)
		return

	if option_index != 0:
		push_warning("Unknown death dialog option: %d" % option_index)
		SceneLoader.change_scene(MAIN_AREA_SCENE_PATH)
		return

	var respawn_point := get_tree().get_first_node_in_group("region_respawn_point") as Node2D
	if respawn_point == null:
		push_error("Current Region does not have a respawn point.")
		SceneLoader.change_scene(MAIN_AREA_SCENE_PATH)
		return

	respawn_at(respawn_point.global_position)


func get_death_destination(option_index: int) -> String:
	if option_index == 1:
		return MAIN_AREA_SCENE_PATH
	if option_index == 2:
		return MAIN_MENU_SCENE_PATH
	return ""


func respawn_at(respawn_position: Vector2) -> void:
	global_position = respawn_position
	health = max_health
	mana = max_mana
	is_dead = false
	is_invincible = true
	invincibility_time_left = invincibility_duration
	dash_time_left = 0.0
	dash_cooldown_left = 0.0
	heal_cooldown_left = 0.0
	area_attack_cooldown_left = 0.0
	knockback_time_left = 0.0
	knockback_direction = Vector2.ZERO
	if animated_sprite != null:
		animated_sprite.visible = true
		animated_sprite.modulate = Color.WHITE
	update_health_bar()
	update_mana_bar()
	update_attack_area()
	update_player_animation(Vector2.ZERO)

	if heal_effect_sprite != null:
		heal_effect_sprite.visible = false
		heal_effect_sprite.stop()

	if death_sound != null:
		death_sound.stop()


func _on_animated_sprite_animation_finished() -> void:
	if is_attacking:
		is_attacking = false
		update_player_animation(Vector2.ZERO)
		return

	if is_casting:
		is_casting = false
		update_player_animation(Vector2.ZERO)


func _on_progression_reward_unlocked(reward_id: StringName) -> void:
	match reward_id:
		&"heal":
			heal_unlocked = true
		&"staff":
			staff_unlocked = true
		&"area_attack":
			area_attack_unlocked = true


func _on_stat_upgrade_changed(_stone_id: StringName, _level: int) -> void:
	_apply_stat_upgrades(true)


func _apply_stat_upgrades(fill_increase: bool) -> void:
	var old_max_health := max_health
	var old_max_mana := max_mana
	max_health = base_max_health + ProgressionManager.get_stat_upgrade_level(&"life") * 10
	max_mana = base_max_mana + ProgressionManager.get_stat_upgrade_level(&"water") * 10
	heal_amount = base_heal_amount + ProgressionManager.get_stat_upgrade_level(&"earth") * 5
	var weapon_level := ProgressionManager.get_stat_upgrade_level(&"light")
	attack_damage = base_attack_damage + weapon_level * 10
	staff_attack_damage = base_staff_attack_damage + weapon_level * 2
	area_attack_damage = base_area_attack_damage + ProgressionManager.get_stat_upgrade_level(&"air") * 15

	if fill_increase:
		health = mini(health + max_health - old_max_health, max_health)
		mana = mini(mana + max_mana - old_max_mana, max_mana)
		update_health_bar()
		update_mana_bar()


func _on_heal_effect_animation_finished() -> void:
	if heal_effect_sprite == null:
		return

	heal_effect_sprite.visible = false
	heal_effect_sprite.stop()
