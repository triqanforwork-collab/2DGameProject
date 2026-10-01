extends "res://scripts/bosses/special_boss.gd"

const ROCK_IMPACT := preload("res://assets/effects/bosses/IceShatter_96x96.png")


func attack_player() -> void:
	if special_active or not can_special_attack(): return
	special_active = true
	var selected := [&"earth_wave", &"roll", &"rock_rain"].pick_random() as StringName
	if selected == last_attack: selected = {&"earth_wave": &"roll", &"roll": &"rock_rain", &"rock_rain": &"earth_wave"}[selected]
	last_attack = selected
	match selected:
		&"earth_wave": await earth_wave()
		&"roll": await rolling_charge()
		&"rock_rain": await rock_rain()
	await finish_special(0.33)


func earth_wave() -> void:
	play_attack_animation()
	await get_tree().create_timer(0.7).timeout
	if not can_special_attack(): return
	var aim := global_position.direction_to(player.global_position)
	for angle in [-24.0, 0.0, 24.0]:
		spawn_projectile(aim.rotated(deg_to_rad(angle)), 230.0, 3, Color(1.0, 0.58, 0.08), 14.0, 2.0)


func rolling_charge() -> void:
	var direction := global_position.direction_to(player.global_position)
	play_attack_animation()
	await show_line_telegraph(direction, 0.7, Color(1.0, 0.55, 0.1), 230.0)
	if not can_special_attack(): return
	var hit := false
	for _frame in 45:
		velocity = direction * 330.0
		move_and_slide()
		if not hit and global_position.distance_to(player.global_position) < 42.0:
			player.take_damage(4, global_position)
			hit = true
		if get_slide_collision_count() > 0: break
		await get_tree().physics_frame
	stop_moving()
	await get_tree().create_timer(1.2).timeout


func rock_rain() -> void:
	play_attack_animation()
	var count := 6 if health <= max_health / 2 else 4
	var radius := 70.0 if health <= max_health / 2 else 62.0
	for index in count:
		var offset := Vector2.from_angle(TAU * index / count) * randf_range(35.0, 115.0)
		var hazard := spawn_hazard(player.global_position + offset, radius, 1.0, 3, Color(0.75, 0.85, 1.0), 1.4)
		hazard.set_repeat_damage(false)
		hazard.set_effect(ROCK_IMPACT, Vector2i(96, 96), 49, 24.0, false, Vector2.ONE * radius / 48.0)
	await get_tree().create_timer(2.5).timeout
