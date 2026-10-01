extends "res://scripts/bosses/special_boss.gd"

const HOLY_EXPLOSION := preload("res://assets/effects/bosses/HolyExplosion_96x96.png")
const LIGHT_CAST := preload("res://assets/effects/bosses/LightCast_96.png")
const LIGHT_SLASH := preload("res://assets/effects/bosses/IcePick_64x64.png")
const LIGHT_CORE := preload("res://assets/effects/bosses/MediumStar_64x64.png")


func attack_player() -> void:
	if special_active or not can_special_attack(): return
	special_active = true
	var selected := [&"charge", &"light_slash", &"pillars"].pick_random() as StringName
	if selected == last_attack: selected = &"pillars" if selected != &"pillars" else &"charge"
	last_attack = selected
	match selected:
		&"charge":
			await charge()
			if health <= max_health / 2 and can_special_attack(): await light_slash(0.35)
		&"light_slash": await light_slash()
		&"pillars": await light_pillars()
	await finish_special(0.25)


func charge() -> void:
	var direction := global_position.direction_to(player.global_position)
	play_attack_animation()
	await show_line_telegraph(direction, 0.75, Color(0.15, 0.8, 1.0), 280.0)
	var hit := false
	for _frame in 42:
		if not can_special_attack(): return
		velocity = direction * 390.0
		move_and_slide()
		if not hit and global_position.distance_to(player.global_position) < 48.0:
			player.take_damage(5, global_position)
			hit = true
		if get_slide_collision_count() > 0: break
		await get_tree().physics_frame
	stop_moving()
	spawn_hazard(global_position, 82.0, 0.15, 3, Color(0.15, 0.8, 1.0))
	spawn_sheet_effect(global_position, HOLY_EXPLOSION, Vector2i(96, 96), 28, 22.0, false, Vector2(1.75, 1.75), Color(0.45, 0.9, 1.0))


func light_slash(delay := 0.7) -> void:
	play_attack_animation()
	await get_tree().create_timer(delay).timeout
	if not can_special_attack(): return
	var aim := global_position.direction_to(player.global_position)
	for angle in [-22.0, 0.0, 22.0]:
		var slash := spawn_projectile(aim.rotated(deg_to_rad(angle)), 300.0, 4, Color(0.2, 0.9, 1.0), 18.0, 2.2)
		slash.set_visual(LIGHT_SLASH, Vector2i(64, 64), 30, 22.0, Vector2(1.65, 1.65), Color(0.55, 0.9, 1.0))


func light_pillars() -> void:
	play_attack_animation()
	var count := 4 if health <= max_health / 2 else 3
	for _index in count:
		if not can_special_attack(): return
		var pillar_position := player.global_position
		spawn_hazard(pillar_position, 68.0, 0.8, 4, Color(0.25, 0.9, 1.0))
		spawn_sheet_effect(pillar_position, LIGHT_CAST, Vector2i(96, 96), 48, 24.0, false, Vector2(1.55, 1.55), Color(0.45, 0.9, 1.0))
		await get_tree().create_timer(0.75).timeout
		spawn_sheet_effect(pillar_position, LIGHT_CORE, Vector2i(64, 64), 60, 30.0, false, Vector2(1.25, 2.8), Color(0.6, 0.95, 1.0))
		await get_tree().create_timer(0.2).timeout
	await get_tree().create_timer(0.8).timeout
