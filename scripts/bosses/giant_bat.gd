extends "res://scripts/bosses/special_boss.gd"

const WIND_BLADE := preload("res://assets/effects/bosses/IcePick_64x64.png")
const DIVE_IMPACT := preload("res://assets/effects/bosses/IceShatter_2_96x96.png")
const TORNADO := preload("res://assets/effects/bosses/TornadoMoving_96x96.png")


func attack_player() -> void:
	if special_active or not can_special_attack(): return
	special_active = true
	var selected := [&"dive", &"wind_blades", &"tornadoes"].pick_random() as StringName
	if selected == last_attack: selected = &"wind_blades" if selected != &"wind_blades" else &"dive"
	last_attack = selected
	match selected:
		&"dive": await dive_attack()
		&"wind_blades": await wind_blades()
		&"tornadoes": await tornadoes()
	await finish_special(0.22 if health <= max_health / 2 else 0.3)


func dive_attack() -> void:
	play_attack_animation()
	AudioManager.play_sfx(&"wind", 0.9, 0.0)
	var landing := player.global_position
	animated_sprite.visible = false
	spawn_hazard(landing, 62.0, 1.0, 5, Color(0.55, 0.85, 1.0))
	await get_tree().create_timer(0.95).timeout
	global_position = landing
	AudioManager.play_sfx(&"earth_slam", 1.1, 0.0)
	animated_sprite.visible = true
	spawn_sheet_effect(landing, DIVE_IMPACT, Vector2i(96, 96), 49, 24.0, false, Vector2(1.4, 1.4), Color(0.55, 0.9, 1.0))
	play_attack_animation()
	await get_tree().create_timer(0.35).timeout


func wind_blades() -> void:
	play_attack_animation()
	var waves := 4 if health <= max_health / 2 else 3
	for wave in waves:
		if not can_special_attack(): return
		AudioManager.play_sfx(&"wind", 1.0 + wave * 0.04, -2.0)
		var aim := global_position.direction_to(player.global_position)
		var blades := 6 if health <= max_health / 2 else 5
		for index in blades:
			var spread := deg_to_rad((index - (blades - 1) * 0.5) * 13.0 + wave * 3.0)
			var blade := spawn_projectile(aim.rotated(spread), 285.0, 3, Color(0.55, 0.85, 1.0), 12.0, 2.3)
			blade.set_visual(WIND_BLADE, Vector2i(64, 64), 30, 22.0, Vector2(1.15, 1.15), Color(0.6, 0.9, 1.0))
		await get_tree().create_timer(0.32).timeout


func tornadoes() -> void:
	play_attack_animation()
	AudioManager.play_sfx(&"tornado", 0.9, -2.0)
	var count := 4 if health <= max_health / 2 else 3
	for index in count:
		var angle := TAU * index / count
		var position := player.global_position + Vector2.from_angle(angle) * 110.0
		var drift := Vector2.from_angle(angle + PI * 0.5) * 28.0
		var tornado := spawn_hazard(position, 48.0, 0.8, 3, Color(0.45, 0.8, 1.0), 4.5, drift)
		tornado.set_circle_opacity(0.025, 0.1, 0.025, 0.08)
		tornado.set_effect(TORNADO, Vector2i(96, 96), 89, 18.0, true, Vector2(1.65, 1.65), Color(0.65, 0.9, 1.0))
	await get_tree().create_timer(1.0).timeout
