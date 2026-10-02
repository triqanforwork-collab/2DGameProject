extends "res://scripts/bosses/special_boss.gd"

const ENERGY_ORB := preload("res://assets/effects/bosses/MagicBarrier_64x64.png")
const LIFE_DRAIN := preload("res://assets/effects/bosses/PoisonCast_96x96.png")
const ICE_SHATTER := preload("res://assets/effects/bosses/IceShatter_96x96.png")
const FIREBALL := preload("res://assets/effects/bosses/FireBall_2_64x64.png")


func attack_player() -> void:
	if special_active or not can_special_attack(): return
	special_active = true
	var selected := [&"energy_storm", &"fireball_volley", &"rock_storm", &"life_drain", &"charge"].pick_random() as StringName
	if selected == last_attack: selected = &"charge" if selected != &"charge" else &"energy_storm"
	last_attack = selected
	match selected:
		&"energy_storm": await energy_storm()
		&"fireball_volley": await fireball_volley()
		&"rock_storm": await rock_storm()
		&"life_drain": await life_drain()
		&"charge": await chained_charge()
	await finish_special(0.13 if health <= max_health / 2 else 0.22)


func fireball_volley() -> void:
	play_attack_animation()
	await get_tree().create_timer(0.65).timeout
	var waves := 7 if health <= max_health / 2 else 5
	for wave in waves:
		if not can_special_attack(): return
		AudioManager.play_sfx(&"fireball", 0.92 + wave * 0.02, -2.0)
		var aim := global_position.direction_to(player.global_position)
		for angle in [-36.0, -24.0, -12.0, 0.0, 12.0, 24.0, 36.0]:
			var fireball := spawn_projectile(aim.rotated(deg_to_rad(angle + wave * 2.0)), 245.0, 4, Color(1.0, 0.35, 0.08), 14.0, 2.5)
			fireball.set_visual(FIREBALL, Vector2i(64, 64), 45, 24.0, Vector2(1.35, 1.35))
		await get_tree().create_timer(0.2).timeout


func energy_storm() -> void:
	play_attack_animation()
	AudioManager.play_sfx(&"energy_storm", 0.9, 0.0)
	await get_tree().create_timer(0.8).timeout
	var waves := 5 if health <= max_health / 2 else 3
	for wave in waves:
		if not can_special_attack(): return
		for index in 8:
			var orb := spawn_projectile(Vector2.from_angle(TAU * index / 8.0 + wave * 0.15), 165.0, 4, Color(0.6, 0.15, 1.0), 14.0, 0.7, 2)
			orb.set_visual(ENERGY_ORB, Vector2i(64, 64), 33, 20.0, Vector2(1.35, 1.35), Color(0.85, 0.55, 1.0))
		await get_tree().create_timer(0.36).timeout


func rock_storm() -> void:
	play_attack_animation()
	AudioManager.play_sfx(&"rock_impact", 0.78, 1.0)
	var count := 8 if health <= max_health / 2 else 6
	for index in count:
		var offset := Vector2.from_angle(TAU * index / count) * randf_range(45.0, 150.0)
		var rock := spawn_hazard(player.global_position + offset, 70.0, randf_range(0.7, 1.05), 4, Color(0.65, 0.8, 1.0), 1.2, Vector2.ZERO, 0.5)
		rock.set_repeat_damage(false)
		rock.set_effect(ICE_SHATTER, Vector2i(96, 96), 49, 24.0, false, Vector2(1.55, 1.55))
	await get_tree().create_timer(1.8).timeout


func life_drain() -> void:
	play_attack_animation()
	AudioManager.play_sfx(&"life_drain", 0.9, 0.0)
	spawn_hazard(global_position, 145.0 if health <= max_health / 2 else 120.0, 0.9, 0, Color(0.55, 0.1, 0.75), 2.6)
	spawn_sheet_effect(global_position, LIFE_DRAIN, Vector2i(96, 96), 40, 18.0, false, Vector2(2.5, 2.5), Color(0.75, 0.45, 1.0))
	await get_tree().create_timer(0.9).timeout
	for _tick in 5:
		if not can_special_attack(): return
		if global_position.distance_to(player.global_position) <= (145.0 if health <= max_health / 2 else 120.0):
			player.take_damage(2, global_position)
			health = mini(max_health, health + 2)
			update_health_bar()
		await get_tree().create_timer(0.45).timeout


func chained_charge() -> void:
	var charges := 4 if health <= max_health / 2 else 3
	for charge_index in charges:
		if not can_special_attack(): return
		var direction := global_position.direction_to(player.global_position)
		AudioManager.play_sfx(&"dash", 0.72 + charge_index * 0.03, 1.0)
		play_attack_animation()
		await show_line_telegraph(direction, 0.65 if charge_index == 0 else 0.4, Color(0.75, 0.15, 1.0), 300.0)
		var hit := false
		for _frame in 38:
			velocity = direction * 410.0
			move_and_slide()
			if not hit and global_position.distance_to(player.global_position) < 64.0:
				player.take_damage(6, global_position)
				hit = true
			if get_slide_collision_count() > 0: break
			await get_tree().physics_frame
		stop_moving()
		spawn_sheet_effect(global_position, ICE_SHATTER, Vector2i(96, 96), 49, 24.0, false, Vector2(1.5, 1.5), Color(0.7, 0.85, 1.0))
