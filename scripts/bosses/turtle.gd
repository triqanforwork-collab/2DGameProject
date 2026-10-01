extends "res://scripts/bosses/boss.gd"

const WATER_PROJECTILE := preload("res://scenes/bosses/Water/TurtleWaterProjectile.tscn")
const LASER_ATTACK := preload("res://scripts/bosses/turtle_laser_attack.gd")

@export var projectile_damage := 2
@export var laser_damage := 3
@export var dash_damage := 4

var special_active := false
var last_attack := &""
var dash_telegraph := false
var dash_direction := Vector2.ZERO


func _physics_process(delta: float) -> void:
	if not special_active:
		super(delta)
		return

	stop_moving()
	if boss_health_bar != null:
		boss_health_bar.visible = has_detected_player and not is_dead


func attack_player() -> void:
	if special_active or is_dead or player == null or not is_instance_valid(player):
		return
	special_active = true
	_run_special_attack(_choose_attack())


func _choose_attack() -> StringName:
	var distance := global_position.distance_to(player.global_position)
	var selected := &"laser"
	if distance < 105.0:
		selected = &"dash"
	elif distance > 185.0:
		selected = &"volley"
	if selected == last_attack:
		selected = {&"volley": &"dash", &"dash": &"laser", &"laser": &"volley"}[selected]
	last_attack = selected
	return selected


func _run_special_attack(attack_name: StringName) -> void:
	match attack_name:
		&"volley": await _water_volley()
		&"laser": await _rotating_lasers()
		&"dash": await _shell_dash()
	if not is_inside_tree() or is_dead:
		return
	play_animation(idle_animation)
	await get_tree().create_timer(0.27).timeout
	if not is_inside_tree() or is_dead:
		return
	special_active = false
	attack_cooldown_left = attack_cooldown


func _water_volley() -> void:
	play_attack_animation()
	await get_tree().create_timer(0.7).timeout
	for wave in 3:
		if not _can_attack():
			return
		var aim := global_position.direction_to(player.global_position)
		for angle_degrees in [-25.0, -12.5, 0.0, 12.5, 25.0]:
			var projectile := WATER_PROJECTILE.instantiate()
			get_tree().current_scene.add_child(projectile)
			projectile.setup(global_position, aim.rotated(deg_to_rad(angle_degrees)), projectile_damage)
		if wave < 2:
			await get_tree().create_timer(0.35).timeout


func _rotating_lasers() -> void:
	play_attack_animation()
	var lasers := LASER_ATTACK.new()
	get_tree().current_scene.add_child(lasers)
	lasers.setup(global_position, player, laser_damage)
	await lasers.finished


func _shell_dash() -> void:
	for dash_index in 3:
		if not _can_attack():
			return
		dash_direction = global_position.direction_to(player.global_position)
		dash_telegraph = true
		queue_redraw()
		play_attack_animation()
		await get_tree().create_timer(0.8 if dash_index == 0 else 0.4).timeout
		dash_telegraph = false
		queue_redraw()
		var hit_player := false
		var dash_time := 0.0
		while dash_time < 0.65 and _can_attack():
			var frame_delta := get_physics_process_delta_time()
			dash_time += frame_delta
			velocity = dash_direction * 360.0
			move_and_slide()
			if not hit_player and global_position.distance_to(player.global_position) <= 45.0:
				player.take_damage(dash_damage, global_position)
				hit_player = true
			if get_slide_collision_count() > 0:
				break
			await get_tree().physics_frame
		stop_moving()


func _can_attack() -> bool:
	return is_inside_tree() and not is_dead and is_instance_valid(player)


func _draw() -> void:
	if dash_telegraph:
		draw_line(Vector2.ZERO, dash_direction * 240.0, Color(1.0, 0.2, 0.1, 0.28), 18.0)
		draw_line(Vector2.ZERO, dash_direction * 240.0, Color(1.0, 0.65, 0.2, 0.9), 3.0)
